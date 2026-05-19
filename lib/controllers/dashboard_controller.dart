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

  MqttServerClient? client;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final StreamController<List<MonitoringLog>> _logsStreamController =
      StreamController<List<MonitoringLog>>.broadcast();

  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();

  final List<MonitoringLog> _currentLogs = [];

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

      final String deviceId = data['device_id']?.toString() ?? 'meja_001';

      final MonitoringLog newLog = MonitoringLog.fromMap(deviceId, data);

      final int existingIndex = _currentLogs.indexWhere(
        (log) => log.id == newLog.id || log.deviceId == newLog.deviceId,
      );

      if (existingIndex != -1) {
        _currentLogs[existingIndex] = newLog;
      } else {
        _currentLogs.add(newLog);
      }

      _logsStreamController.add(List<MonitoringLog>.from(_currentLogs));

      _updateLatestSensorData(deviceId, data);
    } catch (e) {
      _setStatus('MQTT: Error processing message = $e');
    }
  }

  Future<void> _updateLatestSensorData(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final String timestamp = DateTime.now().toString().split('.').first;

    try {
      await _dbRef.child('sensor_data').child(deviceId).set({
        'device_id': deviceId,
        'nama': data['nama'] ?? deviceId,
        'last_update': timestamp,
        'nutrition_value': data['nutrisi'],
        'ph_value': data['ph'],
        'water_value': data['volume'],
        'is_normal': _isSensorNormal(data),
      });

      _setStatus('Firebase: Data terkini berhasil diperbarui untuk $deviceId');
    } catch (e) {
      _setStatus('Firebase: Update sensor_data error = $e');
    }
  }

  bool _isSensorNormal(Map<String, dynamic> data) {
    final double ph = _toDouble(data['ph']);
    final int nutrisi = _toInt(data['nutrisi']);

    final bool phNormal = ph >= 5.5 && ph <= 6.5;
    final bool nutrisiNormal = nutrisi >= 800 && nutrisi <= 1200;

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
    await _setupMqtt();
  }

  void forceDisconnect() {
    client?.disconnect();
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