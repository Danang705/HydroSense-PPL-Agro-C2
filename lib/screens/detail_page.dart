import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../controllers/dashboard_controller.dart';
import '../models/monitoring_log.dart';

class DetailPage extends StatefulWidget {
  final MonitoringLog meja;

  const DetailPage({
    super.key,
    required this.meja,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final DashboardController _mqttController = DashboardController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final TextEditingController _phMinController =
      TextEditingController(text: '5.5');
  final TextEditingController _phMaxController =
      TextEditingController(text: '6.5');
  final TextEditingController _ppmMinController =
      TextEditingController(text: '800');
  final TextEditingController _ppmMaxController =
      TextEditingController(text: '1200');

  final TextEditingController _nutrisiADosisController =
      TextEditingController(text: '20');
  final TextEditingController _nutrisiBDosisController =
      TextEditingController(text: '25');

  final TextEditingController _phUpDosisController =
      TextEditingController(text: '5');
  final TextEditingController _phDownDosisController =
      TextEditingController(text: '5');

  double _activePhMin = 5.5;
  double _activePhMax = 6.5;
  int _activePpmMin = 800;
  int _activePpmMax = 1200;

  bool _isLoadingSetting = true;

  static const String _settingTopic = 'unej/iot/hydrosense/set';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _loadSavedSetting();
  }

  @override
  void dispose() {
    _tabController.dispose();

    _phMinController.dispose();
    _phMaxController.dispose();
    _ppmMinController.dispose();
    _ppmMaxController.dispose();

    _nutrisiADosisController.dispose();
    _nutrisiBDosisController.dispose();

    _phUpDosisController.dispose();
    _phDownDosisController.dispose();

    super.dispose();
  }

  Future<void> _loadSavedSetting() async {
    try {
      final DataSnapshot snapshot = await _dbRef
          .child('device_settings')
          .child(widget.meja.deviceId)
          .get();

      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;

        final double savedPhMin = _toDouble(data['ph_min'], fallback: 5.5);
        final double savedPhMax = _toDouble(data['ph_max'], fallback: 6.5);

        final int savedPpmMin = _toInt(data['ppm_min'], fallback: 800);
        final int savedPpmMax = _toInt(data['ppm_max'], fallback: 1200);

        final int savedNutrisiA =
            _toInt(data['nutrisi_a_dosis_ml'], fallback: 20);
        final int savedNutrisiB =
            _toInt(data['nutrisi_b_dosis_ml'], fallback: 25);

        final int savedPhUp = _toInt(data['ph_up_dosis_ml'], fallback: 5);
        final int savedPhDown = _toInt(data['ph_down_dosis_ml'], fallback: 5);

        if (!mounted) return;

        setState(() {
          _activePhMin = savedPhMin;
          _activePhMax = savedPhMax;
          _activePpmMin = savedPpmMin;
          _activePpmMax = savedPpmMax;

          _phMinController.text = _formatInputNumber(savedPhMin);
          _phMaxController.text = _formatInputNumber(savedPhMax);
          _ppmMinController.text = savedPpmMin.toString();
          _ppmMaxController.text = savedPpmMax.toString();

          _nutrisiADosisController.text = savedNutrisiA.toString();
          _nutrisiBDosisController.text = savedNutrisiB.toString();
          _phUpDosisController.text = savedPhUp.toString();
          _phDownDosisController.text = savedPhDown.toString();

          _isLoadingSetting = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _isLoadingSetting = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingSetting = false;
      });
    }
  }

  String _formatInputNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  double _toDouble(
    dynamic value, {
    required double fallback,
  }) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  int _toInt(
    dynamic value, {
    required int fallback,
  }) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
    }

    return fallback;
  }

  double _getPhMin() {
    return double.tryParse(_phMinController.text.trim()) ?? 5.5;
  }

  double _getPhMax() {
    return double.tryParse(_phMaxController.text.trim()) ?? 6.5;
  }

  int _getPpmMin() {
    return int.tryParse(_ppmMinController.text.trim()) ?? 800;
  }

  int _getPpmMax() {
    return int.tryParse(_ppmMaxController.text.trim()) ?? 1200;
  }

  int _getNutrisiADosis() {
    return int.tryParse(_nutrisiADosisController.text.trim()) ?? 20;
  }

  int _getNutrisiBDosis() {
    return int.tryParse(_nutrisiBDosisController.text.trim()) ?? 25;
  }

  int _getPhUpDosis() {
    return int.tryParse(_phUpDosisController.text.trim()) ?? 5;
  }

  int _getPhDownDosis() {
    return int.tryParse(_phDownDosisController.text.trim()) ?? 5;
  }

  bool _isMqttConnected() {
    return _mqttController.client?.connectionStatus?.state ==
        MqttConnectionState.connected;
  }

  void _publishToMqtt(Map<String, dynamic> data) {
    final String jsonString = jsonEncode(data);

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(jsonString);

    if (_isMqttConnected() && builder.payload != null) {
      _mqttController.client?.publishMessage(
        _settingTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } else {
      throw Exception('MQTT tidak terhubung');
    }
  }

  Future<void> _sendSettingToIoT() async {
    final double phMin = _getPhMin();
    final double phMax = _getPhMax();

    final int ppmMin = _getPpmMin();
    final int ppmMax = _getPpmMax();

    final int nutrisiADosis = _getNutrisiADosis();
    final int nutrisiBDosis = _getNutrisiBDosis();

    final int phUpDosis = _getPhUpDosis();
    final int phDownDosis = _getPhDownDosis();

    if (phMin >= phMax) {
      _showSnackBar(
        message: 'Batas minimal pH harus lebih kecil dari maksimal pH.',
        color: Colors.red,
      );
      return;
    }

    if (ppmMin >= ppmMax) {
      _showSnackBar(
        message:
            'Batas minimal nutrisi harus lebih kecil dari maksimal nutrisi.',
        color: Colors.red,
      );
      return;
    }

    if (nutrisiADosis <= 0 ||
        nutrisiBDosis <= 0 ||
        phUpDosis <= 0 ||
        phDownDosis <= 0) {
      _showSnackBar(
        message: 'Semua dosis otomatis harus lebih dari 0 ml.',
        color: Colors.red,
      );
      return;
    }

    final DateTime now = DateTime.now();
    final String timestamp = now.toString().split('.').first;
    final int timestampMs = now.millisecondsSinceEpoch;

    final Map<String, dynamic> settingData = {
      'id': widget.meja.nama,
      'device_id': widget.meja.deviceId,
      'ph_min': phMin,
      'ph_max': phMax,
      'ppm_min': ppmMin,
      'ppm_max': ppmMax,
      'nutrisi_a_dosis_ml': nutrisiADosis,
      'nutrisi_b_dosis_ml': nutrisiBDosis,
      'ph_up_dosis_ml': phUpDosis,
      'ph_down_dosis_ml': phDownDosis,
    };

    try {
      _publishToMqtt(settingData);

      await _dbRef.child('device_settings').child(widget.meja.deviceId).set({
        ...settingData,
        'updated_at': timestamp,
        'updated_at_ms': timestampMs,
      });

      if (!mounted) return;

      setState(() {
        _activePhMin = phMin;
        _activePhMax = phMax;
        _activePpmMin = ppmMin;
        _activePpmMax = ppmMax;
      });

      await _saveSettingHistory(
        phMin: phMin,
        phMax: phMax,
        ppmMin: ppmMin,
        ppmMax: ppmMax,
        nutrisiADosis: nutrisiADosis,
        nutrisiBDosis: nutrisiBDosis,
        phUpDosis: phUpDosis,
        phDownDosis: phDownDosis,
      );

      _showSnackBar(
        message: 'Setting dan dosis berhasil dikirim ke IoT.',
        color: const Color(0xFF1E3A34),
      );
    } catch (_) {
      _showSnackBar(
        message: 'Gagal! MQTT Tidak Terhubung atau setting gagal disimpan.',
        color: Colors.red,
      );
    }
  }

  Future<void> _sendManualAbMix() async {
    final int nutrisiADosis = _getNutrisiADosis();
    final int nutrisiBDosis = _getNutrisiBDosis();

    if (nutrisiADosis <= 0 || nutrisiBDosis <= 0) {
      _showSnackBar(
        message: 'Dosis AB Mix harus lebih dari 0 ml.',
        color: Colors.red,
      );
      return;
    }

    final Map<String, dynamic> manualAbMixData = {
      'id': widget.meja.nama,
      'device_id': widget.meja.deviceId,
      'mode': 'manual_pump',
      'pump': 'ab_mix',
      'nutrisi_a_dosis_ml': nutrisiADosis,
      'nutrisi_b_dosis_ml': nutrisiBDosis,
    };

    try {
      _publishToMqtt(manualAbMixData);

      await _saveManualPumpHistory(
        pumpLabel: 'AB Mix',
        aksi:
            'Pump manual AB Mix dijalankan dengan Nutrisi A $nutrisiADosis ml dan Nutrisi B $nutrisiBDosis ml',
      );

      _showSnackBar(
        message: 'Pump manual AB Mix berhasil dikirim ke IoT.',
        color: const Color(0xFF1E3A34),
      );
    } catch (_) {
      _showSnackBar(
        message: 'Gagal! MQTT Tidak Terhubung',
        color: Colors.red,
      );
    }
  }

  Future<void> _sendManualPump({
    required String pumpName,
    required String pumpLabel,
    required int dosisMl,
  }) async {
    if (dosisMl <= 0) {
      _showSnackBar(
        message: 'Dosis $pumpLabel harus lebih dari 0 ml.',
        color: Colors.red,
      );
      return;
    }

    final Map<String, dynamic> manualPumpData = {
      'id': widget.meja.nama,
      'device_id': widget.meja.deviceId,
      'mode': 'manual_pump',
      'pump': pumpName,
      'dosis_ml': dosisMl,
    };

    try {
      _publishToMqtt(manualPumpData);

      await _saveManualPumpHistory(
        pumpLabel: pumpLabel,
        aksi: 'Pump manual $pumpLabel dijalankan dengan dosis $dosisMl ml',
      );

      _showSnackBar(
        message: 'Pump manual $pumpLabel berhasil dikirim ke IoT.',
        color: const Color(0xFF1E3A34),
      );
    } catch (_) {
      _showSnackBar(
        message: 'Gagal! MQTT Tidak Terhubung',
        color: Colors.red,
      );
    }
  }

  Future<void> _saveSettingHistory({
    required double phMin,
    required double phMax,
    required int ppmMin,
    required int ppmMax,
    required int nutrisiADosis,
    required int nutrisiBDosis,
    required int phUpDosis,
    required int phDownDosis,
  }) async {
    final DateTime now = DateTime.now();
    final String timestamp = now.toString().split('.').first;
    final int timestampMs = now.millisecondsSinceEpoch;

    await _dbRef.child('device_history').child(widget.meja.deviceId).push().set({
      'device_id': widget.meja.deviceId,
      'meja': widget.meja.nama,
      'ph_value': widget.meja.ph,
      'nutrition_value': widget.meja.nutrisi,
      'water_value': widget.meja.volume,
      'timestamp': timestamp,
      'timestamp_ms': timestampMs,
      'aksi':
          'Pengaturan standar dan dosis diubah: pH $phMin-$phMax, Nutrisi $ppmMin-$ppmMax PPM, Dosis Nutrisi A $nutrisiADosis ml, Dosis Nutrisi B $nutrisiBDosis ml, pH Up $phUpDosis ml, pH Down $phDownDosis ml',
    });
  }

  Future<void> _saveManualPumpHistory({
    required String pumpLabel,
    required String aksi,
  }) async {
    final DateTime now = DateTime.now();
    final String timestamp = now.toString().split('.').first;
    final int timestampMs = now.millisecondsSinceEpoch;

    await _dbRef.child('device_history').child(widget.meja.deviceId).push().set({
      'device_id': widget.meja.deviceId,
      'meja': widget.meja.nama,
      'ph_value': widget.meja.ph,
      'nutrition_value': widget.meja.nutrisi,
      'water_value': widget.meja.volume,
      'timestamp': timestamp,
      'timestamp_ms': timestampMs,
      'aksi': aksi,
    });
  }

  void _showSnackBar({
    required String message,
    required Color color,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  bool _isPhNormal(double ph) {
    return ph >= _activePhMin && ph <= _activePhMax;
  }

  bool _isNutrisiNormal(int nutrisi) {
    return nutrisi >= _activePpmMin && nutrisi <= _activePpmMax;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MonitoringLog>>(
      stream: _mqttController.getMonitoringLogs(),
      initialData: const [],
      builder: (context, snapshot) {
        final List<MonitoringLog> allLogs = snapshot.data ?? [];

        final MonitoringLog currentMeja = allLogs.firstWhere(
          (meja) =>
              meja.deviceId == widget.meja.deviceId ||
              meja.nama == widget.meja.nama,
          orElse: () => widget.meja,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Manajemen Data Meja',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildInfoCard(currentMeja),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMonitoringTab(currentMeja),
                    _buildSettingTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(MonitoringLog meja) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meja.nama,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A34),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meja.createdAt.isEmpty
                          ? 'Update terakhir: Baru saja'
                          : 'Update terakhir: ${meja.createdAt}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF38B2AC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              labelColor: const Color(0xFF1E3A34),
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  icon: Icon(Icons.analytics_outlined),
                ),
                Tab(
                  icon: Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringTab(MonitoringLog meja) {
    final bool phNormal = _isPhNormal(meja.ph);
    final bool nutrisiNormal = _isNutrisiNormal(meja.nutrisi);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildIndicatorCard(
          title: 'PH AIR',
          value: meja.ph.toStringAsFixed(1),
          status: phNormal ? 'Normal' : 'Warning',
          color: phNormal ? Colors.green : Colors.red,
        ),
        _buildIndicatorCard(
          title: 'PPM NUTRISI',
          value: meja.nutrisi.toString(),
          status: nutrisiNormal ? 'Normal' : 'Warning',
          color: nutrisiNormal ? Colors.green : Colors.red,
        ),
        _buildIndicatorCard(
          title: 'VOLUME',
          value: '${meja.volume}%',
          status: 'Normal',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildIndicatorCard({
    required String title,
    required String value,
    required String status,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Indikator',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A34),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTab() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isLoadingSetting
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E3A34),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF1E3A34),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pengaturan Standar Otomatisasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A34),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingField(
                    title: 'BATAS PH AIR',
                    icon: Icons.eco_outlined,
                    minController: _phMinController,
                    maxController: _phMaxController,
                    unit: 'pH',
                  ),
                  const SizedBox(height: 20),
                  _buildSettingField(
                    title: 'BATAS NUTRISI',
                    icon: Icons.bolt_outlined,
                    minController: _ppmMinController,
                    maxController: _ppmMaxController,
                    unit: 'PPM',
                  ),
                  const SizedBox(height: 26),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: Color(0xFF1E3A34),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dosis Otomatis Saat Tidak Normal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A34),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Atur jumlah cairan yang diberikan perangkat ketika nilai sensor berada di luar batas normal.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSingleSettingField(
                    title: 'DOSIS NUTRISI A',
                    icon: Icons.opacity_outlined,
                    controller: _nutrisiADosisController,
                    unit: 'ml',
                    helper:
                        'Diberikan ketika PPM kurang dari batas minimal sebagai larutan nutrisi A.',
                  ),
                  const SizedBox(height: 16),
                  _buildSingleSettingField(
                    title: 'DOSIS NUTRISI B',
                    icon: Icons.opacity_outlined,
                    controller: _nutrisiBDosisController,
                    unit: 'ml',
                    helper:
                        'Diberikan ketika PPM kurang dari batas minimal sebagai larutan nutrisi B.',
                  ),
                  const SizedBox(height: 16),
                  _buildSingleSettingField(
                    title: 'DOSIS PH UP',
                    icon: Icons.arrow_upward_rounded,
                    controller: _phUpDosisController,
                    unit: 'ml',
                    helper: 'Diberikan ketika pH kurang dari batas minimal.',
                  ),
                  const SizedBox(height: 16),
                  _buildSingleSettingField(
                    title: 'DOSIS PH DOWN',
                    icon: Icons.arrow_downward_rounded,
                    controller: _phDownDosisController,
                    unit: 'ml',
                    helper: 'Diberikan ketika pH lebih dari batas maksimal.',
                  ),
                  const SizedBox(height: 26),
                  _buildManualPumpSection(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendSettingToIoT,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A34),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Simpan Standar Ke IoT',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildManualPumpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(
              Icons.water_drop_outlined,
              color: Color(0xFF1E3A34),
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pump Manual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A34),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Jalankan pompa secara manual sesuai dosis yang sudah diatur di atas.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        _manualPumpButton(
          title: 'AB Mix',
          subtitle:
              'A ${_getNutrisiADosis()} ml + B ${_getNutrisiBDosis()} ml',
          icon: Icons.opacity_outlined,
          onTap: _sendManualAbMix,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _manualPumpButton(
                title: 'pH Up',
                subtitle: '${_getPhUpDosis()} ml',
                icon: Icons.arrow_upward_rounded,
                onTap: () {
                  _sendManualPump(
                    pumpName: 'ph_up',
                    pumpLabel: 'pH Up',
                    dosisMl: _getPhUpDosis(),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _manualPumpButton(
                title: 'pH Down',
                subtitle: '${_getPhDownDosis()} ml',
                icon: Icons.arrow_downward_rounded,
                onTap: () {
                  _sendManualPump(
                    pumpName: 'ph_down',
                    pumpLabel: 'pH Down',
                    dosisMl: _getPhDownDosis(),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _manualPumpButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1E3A34),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E3A34),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingField({
    required String title,
    required IconData icon,
    required TextEditingController minController,
    required TextEditingController maxController,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F2F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFF1E3A34),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Color(0xFF1E3A34),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _inputBox(
                label: 'MINIMAL',
                controller: minController,
                unit: unit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputBox(
                label: 'MAKSIMAL',
                controller: maxController,
                unit: unit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleSettingField({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required String unit,
    required String helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F2F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFF1E3A34),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Color(0xFF1E3A34),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helper,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        _inputBox(
          label: 'DOSIS',
          controller: controller,
          unit: unit,
        ),
      ],
    );
  }

  Widget _inputBox({
    required String label,
    required TextEditingController controller,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) {
            setState(() {});
          },
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            suffixText: unit,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}