import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: SafeArea(
        child: StreamBuilder<List<MonitoringLog>>(
          stream: _mqttController.getMonitoringLogs(),
          initialData: const [],
          builder: (context, snapshot) {
            final List<MonitoringLog> allMeja = snapshot.data ?? [];

            final int normalCount =
                allMeja.where((meja) => meja.isNormal).length;
            final int warningCount =
                allMeja.where((meja) => !meja.isNormal).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildMqttStatusCard(),
                const SizedBox(height: 12),
                _buildSummaryRow(normalCount, warningCount),
                const SizedBox(height: 24),
                _buildSectionTitle(),
                const SizedBox(height: 12),
                Expanded(
                  child: allMeja.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: allMeja.length,
                          itemBuilder: (context, index) {
                            return _buildMejaCard(allMeja[index]);
                          },
                        ),
                ),
              ],
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
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Berikut Kondisi Kebun Anda!!!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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
                      await FirebaseAuth.instance.signOut();
                      _mqttController.forceDisconnect();

                      if (!mounted) return;

                      Navigator.pushReplacementNamed(context, '/login');
                    },
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_tethering,
                  size: 18,
                  color: Color(0xFF1E5C3A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D3748),
                      fontWeight: FontWeight.w500,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF2D3748),
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
            color: const Color(0xFF38714F),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            count: warning,
            label: 'Perlu Perhatian',
            color: const Color(0xFFE54D50),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int count,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
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
            color: Color(0xFF38714F),
          ),
          SizedBox(width: 8),
          Text(
            'Status Real-Time Meja',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
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
                color: Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan perangkat IoT sudah aktif dan mengirim data ke topic MQTT.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMejaCard(MonitoringLog meja) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: meja.isNormal
                      ? const Color(0xFF00C48C).withOpacity(0.1)
                      : const Color(0xFFE54D50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  meja.isNormal ? 'NORMAL' : 'TIDAK NORMAL',
                  style: TextStyle(
                    color: meja.isNormal
                        ? const Color(0xFF00C48C)
                        : const Color(0xFFE54D50),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            icon: Icons.opacity_outlined,
            label: 'Nutrisi',
            value: '${meja.nutrisi} PPM',
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            icon: Icons.local_drink_outlined,
            label: 'Volume',
            value: '${meja.volume}%',
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
                color: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lihat Detail',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
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
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF38714F),
          size: 22,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }
}