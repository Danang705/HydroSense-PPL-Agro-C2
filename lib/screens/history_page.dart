import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseReference _historyRef =
      FirebaseDatabase.instance.ref('device_history');

  final TextEditingController _searchController = TextEditingController();

  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _parseHistoryData(dynamic rawData) {
    final List<Map<String, dynamic>> historyList = [];

    if (rawData == null) {
      return historyList;
    }

    if (rawData is Map) {
      rawData.forEach((deviceId, logs) {
        if (logs is Map) {
          logs.forEach((logId, logData) {
            if (logData is Map) {
              final Map<dynamic, dynamic> data = logData;

              historyList.add({
                'id': logId.toString(),
                'device_id': deviceId.toString(),
                'meja': data['meja']?.toString() ??
                    data['nama']?.toString() ??
                    _formatDeviceName(deviceId.toString()),
                'ph': data['ph_value'] ?? data['ph'] ?? '-',
                'nutrisi':
                    data['nutrition_value'] ?? data['nutrisi'] ?? '-',
                'volume': data['water_value'] ?? data['volume'] ?? '-',
                'timestamp': data['timestamp']?.toString() ?? '-',
                'timestamp_ms': data['timestamp_ms'] ?? 0,
                'aksi': data['aksi']?.toString() ??
                    'Aktivitas sistem tercatat',
              });
            }
          });
        }
      });
    }

    historyList.sort((a, b) {
      final int timeA = _toInt(a['timestamp_ms']);
      final int timeB = _toInt(b['timestamp_ms']);

      if (timeA != 0 || timeB != 0) {
        return timeB.compareTo(timeA);
      }

      return b['timestamp'].toString().compareTo(a['timestamp'].toString());
    });

    return historyList;
  }

  List<Map<String, dynamic>> _filterHistory(List<Map<String, dynamic>> logs) {
    final String keyword = _keyword.trim().toLowerCase();

    if (keyword.isEmpty) {
      return logs;
    }

    return logs.where((log) {
      final String meja = log['meja'].toString().toLowerCase();
      final String aksi = log['aksi'].toString().toLowerCase();
      final String timestamp = log['timestamp'].toString().toLowerCase();

      return meja.contains(keyword) ||
          aksi.contains(keyword) ||
          timestamp.contains(keyword);
    }).toList();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  String _formatDeviceName(String id) {
    return id.replaceAll('_', ' ').toUpperCase();
  }

  Future<void> _refreshHistory() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomHeader(),
            _buildSearchField(),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _historyRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E5C3A),
                      ),
                    );
                  }

                  final dynamic rawData = snapshot.data?.snapshot.value;
                  final List<Map<String, dynamic>> allLogs =
                      _parseHistoryData(rawData);
                  final List<Map<String, dynamic>> filteredLogs =
                      _filterHistory(allLogs);

                  if (filteredLogs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF1E5C3A),
                    onRefresh: _refreshHistory,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(filteredLogs[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat & Log Sistem',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pusat audit rekam jejak untuk analisis performa.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _keyword = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari Riwayat',
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.grey,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  log['meja'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1E5C3A),
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                log['timestamp'].toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                _buildLogDetailRow(
                  icon: Icons.sensors,
                  iconColor: Colors.red,
                  label: 'DATA SAAT AKSI',
                  value:
                      'pH: ${log['ph']} | Nutrisi: ${log['nutrisi']} PPM | Volume: ${log['volume']}%',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                _buildLogDetailRow(
                  icon: Icons.settings_input_component_outlined,
                  iconColor: Colors.teal,
                  label: 'AKSI',
                  value: log['aksi'].toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada log aktivitas sistem',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Riwayat hanya akan diisi ketika ada aktivitas penting, seperti perubahan setting IoT.',
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
}