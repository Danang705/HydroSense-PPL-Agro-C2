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

  String _getGreeting() {
    final int hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi!';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang!';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore!';
    } else {
      return 'Selamat Malam!';
    }
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
                    _buildProgressBanner(normalCount, allMeja.length),
                    const SizedBox(height: 16),
                    _buildSummaryRow(normalCount, warningCount),
                    const SizedBox(height: 20),
                    _buildSectionTitle(),
                    const SizedBox(height: 12),
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
                                    height: MediaQuery.of(context).size.height * 0.35,
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: HydroDesign.lightGreenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: HydroDesign.primaryGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: HydroDesign.grayText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: HydroDesign.darkText,
                        letterSpacing: -0.5,
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
              borderRadius: BorderRadius.circular(20),
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

  Widget _buildProgressBanner(int normalCount, int totalCount) {
    final double percent = totalCount > 0 ? (normalCount / totalCount) : 0.0;
    final int percentInt = (percent * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HydroDesign.accentGreenHighlight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: HydroDesign.premiumShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kondisi Kebun Mingguan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: HydroDesign.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    totalCount > 0
                        ? '$normalCount dari $totalCount meja pemantauan berfungsi dalam batas normal.'
                        : 'Menunggu data perangkat untuk analisis.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: HydroDesign.grayText,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 6,
                    color: HydroDesign.secondaryGreen,
                    backgroundColor: Colors.white,
                  ),
                ),
                Text(
                  '$percentInt%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: HydroDesign.darkText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(int normal, int warning) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildSummaryGridCard(
            count: normal,
            label: 'Meja Normal',
            bgColor: const Color(0xFFF1F8E9),
            icon: Icons.check_circle_outline_rounded,
            iconColor: HydroDesign.primaryGreen,
          ),
          const SizedBox(width: 16),
          _buildSummaryGridCard(
            count: warning,
            label: 'Perlu Perhatian',
            bgColor: HydroDesign.dangerRed.withValues(alpha: 0.08),
            icon: Icons.warning_amber_rounded,
            iconColor: HydroDesign.dangerRed,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGridCard({
    required int count,
    required String label,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: HydroDesign.premiumShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: HydroDesign.darkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: HydroDesign.grayText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
            const Text(
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: HydroDesign.premiumShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 52,
            decoration: BoxDecoration(
              color: isNormal ? HydroDesign.secondaryGreen : HydroDesign.dangerRed,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      meja.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: HydroDesign.darkText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isNormal
                            ? HydroDesign.lightGreenBg
                            : HydroDesign.dangerRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isNormal ? 'NORMAL' : 'PERHATIAN',
                        style: TextStyle(
                          color: isNormal
                              ? HydroDesign.primaryGreen
                              : HydroDesign.dangerRed,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCompactParam(Icons.eco_outlined, _formatPh(meja.ph), 'pH', HydroDesign.primaryGreen),
                    const SizedBox(width: 12),
                    _buildCompactParam(Icons.opacity_outlined, '${meja.nutrisi}', 'PPM', HydroDesign.infoTeal),
                    const SizedBox(width: 12),
                    _buildCompactParam(Icons.local_drink_outlined, '${meja.volume}', 'cm', HydroDesign.warningOrange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: HydroDesign.lightGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: HydroDesign.primaryGreen,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactParam(IconData icon, String value, String unit, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: HydroDesign.darkText,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 9,
            color: HydroDesign.grayText,
            fontWeight: FontWeight.bold,
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