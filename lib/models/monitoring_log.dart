class MonitoringLog {
  final String id;
  final String deviceId;
  final bool isNormal;
  final String nama;
  final int nutrisi;
  final double ph;
  final int volume;
  final String createdAt;

  const MonitoringLog({
    required this.id,
    required this.deviceId,
    required this.isNormal,
    required this.nama,
    required this.nutrisi,
    required this.ph,
    required this.volume,
    required this.createdAt,
  });

  factory MonitoringLog.fromMap(String id, Map<dynamic, dynamic> map) {
    final double phValue = _toDouble(map['ph']);
    final int nutrisiValue = _toInt(map['nutrisi']);
    final int volumeValue = _toInt(map['volume']);

    return MonitoringLog(
      id: id,
      deviceId: map['device_id']?.toString() ?? id,
      isNormal: map['isNormal'] ?? _checkNormalStatus(
        ph: phValue,
        nutrisi: nutrisiValue,
      ),
      nama: map['nama']?.toString() ?? _formatDeviceName(id),
      nutrisi: nutrisiValue,
      ph: phValue,
      volume: volumeValue,
      createdAt: map['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'isNormal': isNormal,
      'nama': nama,
      'nutrisi': nutrisi,
      'ph': ph,
      'volume': volume,
      'created_at': createdAt,
    };
  }

  static bool _checkNormalStatus({
    required double ph,
    required int nutrisi,
  }) {
    final bool phNormal = ph >= 5.5 && ph <= 6.5;
    final bool nutrisiNormal = nutrisi >= 800 && nutrisi <= 1200;

    return phNormal && nutrisiNormal;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }

    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  static String _formatDeviceName(String id) {
    if (id.isEmpty) return 'Meja';

    final String formatted = id
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');

    return formatted;
  }
}