import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/monitoring_log.dart';

class DashboardController {
  DashboardController._internal() {
    debugPrint('DashboardController dibuat');
    _loadLatestSensorDataFromFirebase();
    _setupMqtt();
  }

  static final DashboardController _instance = DashboardController._internal();

  factory DashboardController() {
    return _instance;
  }

  static const String _mqttHost =
      'c4707373649a4f5e835210ba759d16e7.s1.eu.hivemq.cloud';
  static const int _mqttPort = 8883;
  static const String _mqttUsername = 'riomario';
  static const String _mqttPassword = 'Rio123123';

  static const String _dataTopic = 'unej/iot/hydrosense/data';

  // Hanya pakai device ini saja.
  // Data dari meja_01 atau device lain akan diabaikan.
  static const String _allowedDeviceId = 'meja_001';

  // Simpan data terakhir ke Firebase maksimal 1 menit sekali.
  // Kalau mau 5 menit sekali, ubah jadi 300.
  static const int _firebaseSaveIntervalSeconds = 60;

  MqttServerClient? client;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final StreamController<List<MonitoringLog>> _logsStreamController =
      StreamController<List<MonitoringLog>>.broadcast();

  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();

  final List<MonitoringLog> _currentLogs = [];

  final Map<String, DateTime> _lastFirebaseSaveAt = {};

  Stream<List<MonitoringLog>> getMonitoringLogs() {
    return _logsStreamController.stream;
  }

  Stream<String> getMqttStatus() {
    return _statusStreamController.stream;
  }

  void _setStatus(String status) {
    debugPrint(status);

    if (!_statusStreamController.isClosed) {
      _statusStreamController.add(status);
    }
  }

  Future<void> _loadLatestSensorDataFromFirebase() async {
    try {
      final DataSnapshot snapshot = await _dbRef.child('sensor_data').get();

      if (!snapshot.exists || snapshot.value is! Map) {
        _setStatus('Firebase: Belum ada data sensor terakhir');
        return;
      }

      final Map<dynamic, dynamic> firebaseData =
          snapshot.value as Map<dynamic, dynamic>;

      _currentLogs.clear();

      firebaseData.forEach((key, value) {
        if (value is Map) {
          final String firebaseKey = key.toString();

          final Map<String, dynamic> data = _normalizeFirebaseSensorData(
            deviceId: firebaseKey,
            rawData: value,
          );

          final MonitoringLog log = MonitoringLog.fromJson(data);

          // Hanya ambil meja_001.
          // Node lama seperti meja_01 akan diabaikan.
          if (log.deviceId != _allowedDeviceId) {
            _setStatus('Firebase: Data ${log.deviceId} diabaikan');
            return;
          }

          _currentLogs.add(log);
        }
      });

      _logsStreamController.add(List<MonitoringLog>.from(_currentLogs));

      _setStatus('Firebase: Data sensor terakhir meja_001 berhasil dimuat');
    } catch (e) {
      _setStatus('Firebase: Gagal memuat sensor_data = $e');
    }
  }

  Map<String, dynamic> _normalizeFirebaseSensorData({
    required String deviceId,
    required Map<dynamic, dynamic> rawData,
  }) {
    return {
      'device_id': rawData['device_id'] ?? deviceId,
      'nama': rawData['nama'] ?? 'Meja 1',
      'ph': rawData['ph'] ?? rawData['ph_value'] ?? 0,
      'nutrisi': rawData['nutrisi'] ?? rawData['nutrition_value'] ?? 0,
      'volume': rawData['volume'] ??
          rawData['volume_meter'] ??
          rawData['water_value'] ??
          0,
      'created_at': rawData['created_at'] ??
          rawData['last_update'] ??
          rawData['timestamp'] ??
          '',
    };
  }

  Future<void> _setupMqtt() async {
    final String uniqueClientId =
        'hydrosense_flutter_${DateTime.now().millisecondsSinceEpoch}';

    _setStatus('MQTT: Membuat client...');

    client = MqttServerClient.withPort(
      _mqttHost,
      uniqueClientId,
      _mqttPort,
    );

    client!
      ..secure = true
      ..securityContext = SecurityContext.defaultContext
      ..setProtocolV311()
      ..logging(on: true)
      ..keepAlivePeriod = 20
      ..connectTimeoutPeriod = 10000
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onSubscribed = _onSubscribed
      ..onSubscribeFail = _onSubscribeFail
      ..pongCallback = _onPong;

    client!.onBadCertificate = (dynamic certificate) {
      _setStatus('MQTT: Bad certificate diterima, tetap lanjut');
      return true;
    };

    final MqttConnectMessage connectMessage = MqttConnectMessage()
        .authenticateAs(_mqttUsername, _mqttPassword)
        .withClientIdentifier(uniqueClientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client!.connectionMessage = connectMessage;

    try {
      _setStatus('MQTT: Mencoba connect ke $_mqttHost:$_mqttPort...');
      _setStatus('MQTT: Client ID = $uniqueClientId');

      await client!.connect();

      final MqttConnectionState? state = client!.connectionStatus?.state;

      _setStatus('MQTT: State setelah connect = $state');

      if (state == MqttConnectionState.connected) {
        _setStatus('MQTT: Berhasil connect');
        _subscribeToTopic();
      } else {
        _setStatus('MQTT: Gagal connect. Status: ${client!.connectionStatus}');
        client?.disconnect();
      }
    } catch (e) {
      _setStatus('MQTT: Exception saat connect = $e');
      client?.disconnect();
    }
  }

  void _subscribeToTopic() {
    if (client == null) {
      _setStatus('MQTT: Client null, tidak bisa subscribe');
      return;
    }

    if (client!.connectionStatus?.state != MqttConnectionState.connected) {
      _setStatus('MQTT: Belum connected, tidak bisa subscribe');
      return;
    }

    _setStatus('MQTT: Subscribe ke topic $_dataTopic');

    client!.subscribe(_dataTopic, MqttQos.atMostOnce);

    client!.updates?.listen(
      (List<MqttReceivedMessage<MqttMessage>> messages) {
        if (messages.isEmpty) {
          _setStatus('MQTT: Pesan kosong diterima');
          return;
        }

        final MqttPublishMessage receivedMessage =
            messages.first.payload as MqttPublishMessage;

        final String payload = MqttPublishPayload.bytesToStringAsString(
          receivedMessage.payload.message,
        );

        _setStatus('MQTT: Payload masuk = $payload');

        _onMessageReceived(payload);
      },
      onError: (error) {
        _setStatus('MQTT: Updates error = $error');
      },
      onDone: () {
        _setStatus('MQTT: Updates stream selesai');
      },
    );
  }

  void _onConnected() {
    _setStatus('MQTT: Connected callback terpanggil');
  }

  void _onDisconnected() {
    _setStatus('MQTT: Disconnected callback terpanggil');
    _setStatus('MQTT: Disconnect status = ${client?.connectionStatus}');
  }

  void _onSubscribed(String topic) {
    _setStatus('MQTT: Berhasil subscribe topic $topic');
  }

  void _onSubscribeFail(String topic) {
    _setStatus('MQTT: Gagal subscribe topic $topic');
  }

  void _onPong() {
    _setStatus('MQTT: Pong diterima');
  }

  void _onMessageReceived(String payload) {
    try {
      final dynamic decodedData = json.decode(payload);

      if (decodedData is! Map<String, dynamic>) {
        _setStatus('MQTT: Payload bukan JSON object valid');
        return;
      }

      final Map<String, dynamic> data = decodedData;

      final MonitoringLog newLog = MonitoringLog.fromJson(data).copyWith(
        createdAt: DateTime.now().toString().split('.').first,
      );

      // Hanya proses data dari meja_001.
      // Kalau ESP32/device lain mengirim meja_01, langsung diabaikan.
      if (newLog.deviceId != _allowedDeviceId) {
        _setStatus('MQTT: Data ${newLog.deviceId} diabaikan');
        return;
      }

      final int existingIndex = _currentLogs.indexWhere(
        (log) => log.deviceId == newLog.deviceId,
      );

      if (existingIndex != -1) {
        _currentLogs[existingIndex] = newLog;
      } else {
        _currentLogs.add(newLog);
      }

      // Dashboard dan DetailPage tetap realtime setiap MQTT masuk.
      _logsStreamController.add(List<MonitoringLog>.from(_currentLogs));

      // Firebase hanya disimpan sesuai interval agar tidak penuh.
      _saveLatestSensorDataWithInterval(newLog);
    } catch (e) {
      _setStatus('MQTT: Error processing message = $e');
    }
  }

  Future<void> _saveLatestSensorDataWithInterval(MonitoringLog log) async {
    final DateTime now = DateTime.now();
    final DateTime? lastSave = _lastFirebaseSaveAt[log.deviceId];

    if (lastSave != null) {
      final int diffSeconds = now.difference(lastSave).inSeconds;

      if (diffSeconds < _firebaseSaveIntervalSeconds) {
        _setStatus(
          'Firebase: Skip simpan ${log.deviceId}, belum $_firebaseSaveIntervalSeconds detik',
        );
        return;
      }
    }

    _lastFirebaseSaveAt[log.deviceId] = now;

    await _saveLatestSensorData(log);
  }

  Future<void> _saveLatestSensorData(MonitoringLog log) async {
    final DateTime now = DateTime.now();
    final String timestamp = now.toString().split('.').first;
    final int timestampMs = now.millisecondsSinceEpoch;

    try {
      await _dbRef.child('sensor_data').child(_allowedDeviceId).set({
        'device_id': _allowedDeviceId,
        'nama': 'Meja 1',

        // Format baru.
        'ph': log.ph,
        'nutrisi': log.nutrisi,
        'volume': log.volume,
        'created_at': timestamp,

        // Format lama, biar tetap cocok kalau ada page lain masih baca key lama.
        'ph_value': log.ph,
        'nutrition_value': log.nutrisi,
        'water_value': log.volume,
        'volume_meter': log.volume,
        'last_update': timestamp,
        'last_update_ms': timestampMs,

        'is_normal': _isSensorNormal(log),
      });

      _setStatus('Firebase: Data terakhir disimpan untuk $_allowedDeviceId');
    } catch (e) {
      _setStatus('Firebase: Update sensor_data error = $e');
    }
  }

  bool _isSensorNormal(MonitoringLog log) {
    final bool phNormal = log.ph >= 5.5 && log.ph <= 6.5;
    final bool nutrisiNormal = log.nutrisi >= 800 && log.nutrisi <= 1200;

    return phNormal && nutrisiNormal;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }

    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  Future<void> reconnect() async {
    _setStatus('MQTT: Reconnect manual...');
    client?.disconnect();

    await Future.delayed(const Duration(seconds: 1));

    await _loadLatestSensorDataFromFirebase();
    await _setupMqtt();
  }

  void forceDisconnect() {
    client?.disconnect();

    // Saat logout, tampilan dikosongkan.
    // Data terakhir tetap aman di Firebase sensor_data/meja_001.
    _currentLogs.clear();
    _logsStreamController.add(List<MonitoringLog>.from(_currentLogs));

    _setStatus('MQTT: Berhenti karena logout');
  }

  void dispose() {
    client?.disconnect();
    _logsStreamController.close();
    _statusStreamController.close();
  }
}