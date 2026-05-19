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

  final TextEditingController _nutrisiDosisController =
      TextEditingController(text: '20');
  final TextEditingController _phUpDosisController =
      TextEditingController(text: '5');
  final TextEditingController _phDownDosisController =
      TextEditingController(text: '5');

  static const String _settingTopic = 'unej/iot/hydrosense/set';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();

    _phMinController.dispose();
    _phMaxController.dispose();
    _ppmMinController.dispose();
    _ppmMaxController.dispose();

    _nutrisiDosisController.dispose();
    _phUpDosisController.dispose();
    _phDownDosisController.dispose();

    super.dispose();
  }

  Future<void> _sendSettingToIoT() async {
    final double phMin = double.tryParse(_phMinController.text.trim()) ?? 5.5;
    final double phMax = double.tryParse(_phMaxController.text.trim()) ?? 6.5;
    final int ppmMin = int.tryParse(_ppmMinController.text.trim()) ?? 800;
    final int ppmMax = int.tryParse(_ppmMaxController.text.trim()) ?? 1200;

    final int nutrisiDosis =
        int.tryParse(_nutrisiDosisController.text.trim()) ?? 20;
    final int phUpDosis = int.tryParse(_phUpDosisController.text.trim()) ?? 5;
    final int phDownDosis =
        int.tryParse(_phDownDosisController.text.trim()) ?? 5;

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

    if (nutrisiDosis <= 0 || phUpDosis <= 0 || phDownDosis <= 0) {
      _showSnackBar(
        message: 'Dosis otomatis harus lebih dari 0 ml.',
        color: Colors.red,
      );
      return;
    }

    final Map<String, dynamic> settingData = {
      'id': widget.meja.nama,
      'device_id': widget.meja.deviceId,
      'ph_min': phMin,
      'ph_max': phMax,
      'ppm_min': ppmMin,
      'ppm_max': ppmMax,
      'nutrisi_dosis_ml': nutrisiDosis,
      'ph_up_dosis_ml': phUpDosis,
      'ph_down_dosis_ml': phDownDosis,
    };

    final String jsonString = jsonEncode(settingData);

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(jsonString);

    final bool isConnected = _mqttController.client?.connectionStatus?.state ==
        MqttConnectionState.connected;

    if (isConnected && builder.payload != null) {
      _mqttController.client?.publishMessage(
        _settingTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      try {
        await _saveSettingHistory(
          phMin: phMin,
          phMax: phMax,
          ppmMin: ppmMin,
          ppmMax: ppmMax,
          nutrisiDosis: nutrisiDosis,
          phUpDosis: phUpDosis,
          phDownDosis: phDownDosis,
        );

        _showSnackBar(
          message: 'Setting dan dosis berhasil dikirim ke IoT.',
          color: const Color(0xFF1E3A34),
        );
      } catch (e) {
        _showSnackBar(
          message: 'Data terkirim ke HiveMQ, tapi gagal menyimpan riwayat.',
          color: Colors.orange,
        );
      }
    } else {
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
    required int nutrisiDosis,
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
          'Pengaturan standar dan dosis diubah: pH $phMin-$phMax, Nutrisi $ppmMin-$ppmMax PPM, Dosis Nutrisi $nutrisiDosis ml, pH Up $phUpDosis ml, pH Down $phDownDosis ml',
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
    final bool phNormal = meja.ph >= 5.5 && meja.ph <= 6.5;
    final bool nutrisiNormal = meja.nutrisi >= 800 && meja.nutrisi <= 1200;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildIndicatorCard(
          title: 'PH AIR',
          value: meja.ph.toString(),
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
        child: Column(
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
              title: 'DOSIS NUTRISI',
              icon: Icons.opacity_outlined,
              controller: _nutrisiDosisController,
              unit: 'ml',
              helper: 'Diberikan ketika PPM kurang dari batas minimal.',
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