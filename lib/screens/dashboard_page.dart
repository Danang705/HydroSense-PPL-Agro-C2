import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_notification.dart';
import '../widgets/hydro_design.dart';
import '../controllers/dashboard_controller.dart';
import '../models/monitoring_log.dart';
import 'detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  final DashboardController _mqttController = DashboardController();

  @override
  bool get wantKeepAlive => true;

  String _getDisplayName(User? user) {
    final String? displayName = user?.displayName;

    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    final String? email = user?.email;

    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Admin';
  }

  String _formatPh(double ph) {
    return ph.toStringAsFixed(1);
  }

  Map<String, _DashboardDeviceSetting> _parseDeviceSettings(dynamic value) {
    final Map<String, _DashboardDeviceSetting> result = {};

    if (value is! Map) {
      return result;
    }

    value.forEach((key, item) {
      if (item is Map) {
        final String deviceId = key.toString();

        result[deviceId] = _DashboardDeviceSetting(
          phMin: _toDouble(item['ph_min'], fallback: 5.5),
          phMax: _toDouble(item['ph_max'], fallback: 6.5),
          ppmMin: _toInt(item['ppm_min'], fallback: 800),
          ppmMax: _toInt(item['ppm_max'], fallback: 1200),
        );
      }
    });

    return result;
  }

  _DashboardDeviceSetting _getSettingForMeja(
    MonitoringLog meja,
    Map<String, _DashboardDeviceSetting> settings,
  ) {
    return settings[meja.deviceId] ??
        settings[meja.nama] ??
        const _DashboardDeviceSetting(
          phMin: 5.5,
          phMax: 6.5,
          ppmMin: 800,
          ppmMax: 1200,
        );
  }

  bool _isPhNormal(
    MonitoringLog meja,
    Map<String, _DashboardDeviceSetting> settings,
  ) {
    final _DashboardDeviceSetting setting = _getSettingForMeja(meja, settings);

    return meja.ph >= setting.phMin && meja.ph <= setting.phMax;
  }

  bool _isNutrisiNormal(
    MonitoringLog meja,
    Map<String, _DashboardDeviceSetting> settings,
  ) {
    final _DashboardDeviceSetting setting = _getSettingForMeja(meja, settings);

    return meja.nutrisi >= setting.ppmMin && meja.nutrisi <= setting.ppmMax;
  }

  bool _isVolumeNormal(MonitoringLog meja) {
    return true;
  }

  bool _isMejaNormal(
    MonitoringLog meja,
    Map<String, _DashboardDeviceSetting> settings,
  ) {
    final bool phNormal = _isPhNormal(meja, settings);
    final bool nutrisiNormal = _isNutrisiNormal(meja, settings);
    final bool volumeNormal = _isVolumeNormal(meja);

    return phNormal && nutrisiNormal && volumeNormal;
  }

  int _toInt(
    dynamic value, {
    required int fallback,
  }) {
    if (value == null) return fallback;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is num) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
    }

    return fallback;
  }

  double _toDouble(
    dynamic value, {
    required double fallback,
  }) {
    if (value == null) return fallback;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: HydroDesign.background,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('device_settings').onValue,
          builder: (context, settingSnapshot) {
            final Map<String, _DashboardDeviceSetting> deviceSettings =
                _parseDeviceSettings(settingSnapshot.data?.snapshot.value);

            return StreamBuilder<List<MonitoringLog>>(
              stream: _mqttController.getMonitoringLogs(),
              initialData: const [],
              builder: (context, snapshot) {
                final List<MonitoringLog> allMeja = snapshot.data ?? [];

                final int normalCount = allMeja
                    .where((meja) => _isMejaNormal(meja, deviceSettings))
                    .length;

                final int warningCount = allMeja
                    .where((meja) => !_isMejaNormal(meja, deviceSettings))
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildMqttStatusCard(),
                    const SizedBox(height: 16),
                    _buildSummaryRow(normalCount, warningCount),
                    const SizedBox(height: 24),
                    _buildSectionTitle(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _mqttController.reconnect();
                          await Future.delayed(const Duration(milliseconds: 1000));
                        },
                        color: HydroDesign.primaryGreen,
                        child: allMeja.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: Center(
                                      child: _buildEmptyState(),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: allMeja.length,
                                itemBuilder: (context, index) {
                                  final MonitoringLog meja = allMeja[index];
                                  final bool isNormal =
                                      _isMejaNormal(meja, deviceSettings);

                                  return _buildMejaCard(
                                    meja: meja,
                                    isNormal: isNormal,
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final User? user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        final String displayName = _getDisplayName(user);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo $displayName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: HydroDesign.darkText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Berikut Kondisi Kebun Anda!!!',
                      style: TextStyle(
                        fontSize: 14,
                        color: HydroDesign.grayText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _buildCircleIcon(
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      _mqttController.reconnect();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCircleIcon(
                    icon: Icons.logout_rounded,
                    onTap: () async {
                      final bool confirm = await HydroNotification.showConfirmDialog(
                        context: context,
                        title: 'Keluar Akun',
                        message: 'Apakah kamu yakin ingin keluar dari aplikasi?',
                        confirmText: 'KELUAR',
                        cancelText: 'BATAL',
                        isDestructive: true,
                      );

                      if (!confirm) return;

                      await FirebaseAuth.instance.signOut();
                      _mqttController.forceDisconnect();

                      if (!context.mounted) return;

                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    iconColor: HydroDesign.dangerRed,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMqttStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<String>(
        stream: _mqttController.getMqttStatus(),
        initialData: 'MQTT: Menyiapkan koneksi...',
        builder: (context, snapshot) {
          final String status = snapshot.data ?? 'MQTT: Tidak ada status';

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: HydroDesign.premiumShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: HydroDesign.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_tethering,
                    size: 16,
                    color: HydroDesign.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: HydroDesign.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircleIcon({
    required IconData icon,
    required VoidCallback? onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: HydroDesign.premiumShadow,
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? HydroDesign.darkText,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(int normal, int warning) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildSummaryCard(
            count: normal,
            label: 'Normal',
            gradient: const LinearGradient(
              colors: [Color(0xFF1E5C3A), Color(0xFF2D7A50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            count: warning,
            label: 'Perlu Perhatian',
            gradient: const LinearGradient(
              colors: [Color(0xFFE54D50), Color(0xFFF07173)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int count,
    required String label,
    required Gradient gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(
            Icons.layers_outlined,
            size: 20,
            color: HydroDesign.primaryGreen,
          ),
          SizedBox(width: 8),
          Text(
            'Status Real-Time Meja',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: HydroDesign.darkText,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sensors_off_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Menunggu data alat...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HydroDesign.darkText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan perangkat IoT sudah aktif dan mengirim data ke topic MQTT.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HydroDesign.grayText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMejaCard({
    required MonitoringLog meja,
    required bool isNormal,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: HydroDesign.premiumShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meja.nama,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: HydroDesign.darkText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isNormal
                      ? const Color(0xFF00C48C).withValues(alpha: 0.12)
                      : const Color(0xFFE54D50).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isNormal ? 'NORMAL' : 'TIDAK NORMAL',
                  style: TextStyle(
                    color: isNormal
                        ? const Color(0xFF00C48C)
                        : const Color(0xFFE54D50),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDataRow(
            icon: Icons.eco_outlined,
            label: 'pH Air',
            value: _formatPh(meja.ph),
            color: HydroDesign.primaryGreen,
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            icon: Icons.opacity_outlined,
            label: 'Nutrisi',
            value: '${meja.nutrisi} PPM',
            color: HydroDesign.infoTeal,
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            icon: Icons.local_drink_outlined,
            label: 'Volume',
            value: '${meja.volume} cm',
            color: HydroDesign.warningOrange,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(meja: meja),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.06),
                ),
                color: HydroDesign.lightGreenBg.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lihat Detail',
                    style: TextStyle(
                      color: HydroDesign.primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: HydroDesign.primaryGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: HydroDesign.grayText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: HydroDesign.darkText,
          ),
        ),
      ],
    );
  }
}

class _DashboardDeviceSetting {
  final double phMin;
  final double phMax;
  final int ppmMin;
  final int ppmMax;

  const _DashboardDeviceSetting({
    required this.phMin,
    required this.phMax,
    required this.ppmMin,
    required this.ppmMax,
  });
}