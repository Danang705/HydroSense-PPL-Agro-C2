class MonitoringLog {
  final String deviceId;
  final String nama;
  final double ph;
  final int nutrisi;
  final int volume;
  final String createdAt;
  final String aksi;

  MonitoringLog({
    String? deviceId,
    String? id,
    String? nama,
    String? meja,
    double? ph,
    double? phValue,
    dynamic nutritionValue,
    dynamic nutrisi,
    dynamic waterValue,
    dynamic volume,
    String? createdAt,
    String? timestamp,
    String? aksi,
    String? action,
  })  : deviceId = _toStringValue(
          deviceId ?? id,
          fallback: 'meja_001',
        ),
        nama = _toStringValue(
          nama ?? meja,
          fallback: 'Meja 1',
        ),
        ph = _toDouble(
          ph ?? phValue,
          fallback: 0.0,
        ),
        nutrisi = _toInt(
          nutrisi ?? nutritionValue,
          fallback: 0,
        ),
        volume = _toInt(
          volume ?? waterValue,
          fallback: 0,
        ),
        createdAt = _toStringValue(
          createdAt ?? timestamp,
          fallback: '',
        ),
        aksi = _toStringValue(
          aksi ?? action,
          fallback: '',
        );

  bool get isPhNormal {
    return ph >= 5.5 && ph <= 6.5;
  }

  bool get isNutrisiNormal {
    return nutrisi >= 800 && nutrisi <= 1200;
  }

  bool get isVolumeNormal {
    return volume >= 20;
  }

  bool get isNormal {
    return isPhNormal && isNutrisiNormal && isVolumeNormal;
  }

  factory MonitoringLog.fromJson(Map<dynamic, dynamic> json) {
    return MonitoringLog(
      deviceId: json['device_id'] ?? json['deviceId'] ?? json['id'],
      nama: json['nama'] ?? json['meja'],
      ph: _toDouble(
        json['ph'] ?? json['ph_value'] ?? json['phValue'],
        fallback: 0.0,
      ),
      nutrisi: _toInt(
        json['nutrisi'] ??
            json['nutrition_value'] ??
            json['nutritionValue'],
        fallback: 0,
      ),
      volume: _toInt(
        json['volume'] ?? json['water_value'] ?? json['waterValue'],
        fallback: 0,
      ),
      createdAt: _toStringValue(
        json['created_at'] ??
            json['createdAt'] ??
            json['timestamp'] ??
            json['updated_at'],
        fallback: '',
      ),
      aksi: _toStringValue(
        json['aksi'] ?? json['action'],
        fallback: '',
      ),
    );
  }

  factory MonitoringLog.fromMap(Map<dynamic, dynamic> map) {
    return MonitoringLog.fromJson(map);
  }

  factory MonitoringLog.fromFirebase(Map<dynamic, dynamic> data) {
    return MonitoringLog.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'nama': nama,
      'ph': ph,
      'nutrisi': nutrisi,
      'volume': volume,
      'created_at': createdAt,
      'aksi': aksi,
    };
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'device_id': deviceId,
      'meja': nama,
      'ph_value': ph,
      'nutrition_value': nutrisi,
      'water_value': volume,
      'timestamp': createdAt,
      'aksi': aksi,
    };
  }

  MonitoringLog copyWith({
    String? deviceId,
    String? nama,
    double? ph,
    int? nutrisi,
    int? volume,
    String? createdAt,
    String? aksi,
  }) {
    return MonitoringLog(
      deviceId: deviceId ?? this.deviceId,
      nama: nama ?? this.nama,
      ph: ph ?? this.ph,
      nutrisi: nutrisi ?? this.nutrisi,
      volume: volume ?? this.volume,
      createdAt: createdAt ?? this.createdAt,
      aksi: aksi ?? this.aksi,
    );
  }

  static String _toStringValue(
    dynamic value, {
    required String fallback,
  }) {
    if (value == null) return fallback;

    final String result = value.toString().trim();

    if (result.isEmpty) return fallback;

    return result;
  }

  static double _toDouble(
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

  static int _toInt(
    dynamic value, {
    required int fallback,
  }) {
    if (value == null) return fallback;

    if (value is int) return value;

    if (value is double) return value.round();

    if (value is num) return value.round();

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.round() ?? fallback;
    }

    return fallback;
  }
}