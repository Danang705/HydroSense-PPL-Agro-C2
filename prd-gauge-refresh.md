# Product Requirements Document (PRD) - Visual Circular Gauge & Pull-to-Refresh HydroSense

Dokumen ini mendefinisikan kebutuhan pengembangan untuk dua fitur interaktivitas baru pada sisi Flutter aplikasi **HydroSense**:
1. **Visual Circular Gauge (Animasi Pengukur Sensor)** pada Halaman Detail.
2. **Pull-to-Refresh (Tarik untuk Menyegarkan)** pada Halaman Dashboard dan Detail.

Kedua fitur ini diimplementasikan sepenuhnya di sisi front-end (Flutter) tanpa membutuhkan perubahan pada backend Firebase maupun broker MQTT.

---

## 1. Fitur 1: Visual Circular Gauge (Animasi Pengukur Sensor)

### A. Deskripsi & Tujuan
Mengubah visualisasi data sensor statis pada [detail_page.dart](file:///d:/SEMESTER%204/PPL/aplikasi/HydroSense-PPL-Agro-C2/lib/screens/detail_page.dart) menjadi representasi grafis berupa cincin pengukur melingkar (Circular Gauge) yang responsif dan interaktif. Ini memberikan pengalaman panel kontrol profesional yang mewah bagi pengguna.

### B. Spesifikasi Desain & Logika Warna
* **Parameter Pengukuran**:
  1. **pH Air** (Skala 0 - 14):
     * Rentang Normal: Sesuai konfigurasi `_activePhMin` dan `_activePhMax` (default 5.5 - 6.5).
     * Logika Warna: Hijau (`#38714F`) jika berada dalam batas normal. Merah/Oranye (`#E54D50`) jika di bawah batas minimal (terlalu asam) atau di atas batas maksimal (terlahu basa).
  2. **PPM Nutrisi** (Skala 0 - 2000):
     * Rentang Normal: Sesuai konfigurasi `_activePpmMin` dan `_activePpmMax` (default 800 - 1200).
     * Logika Warna: Hijau (`#38714F`) jika normal. Merah/Kuning jika PPM terlalu rendah (kurang nutrisi) atau terlalu tinggi (over-nutrition).
  3. **Volume Air** (Skala 0% - 100%):
     * Menggunakan warna biru air/teal dinamis (`#38B2AC`).
* **Estetika Visual**:
  * Sudut membulat pada ujung progres cincin (*StrokeCap.round*).
  * Efek bayangan cahaya lembut di belakang cincin (Glow effect) menggunakan `BoxShadow` atau `ShaderMask`.
  * Teks angka utama tetap berada tepat di tengah lingkaran dengan font tebal berwarna gelap (`#1E3A34`).
  * Label sensor diletakkan di bagian bawah lingkaran.

---

## 2. Fitur 2: Pull-to-Refresh (Tarik untuk Menyegarkan)

### A. Deskripsi & Tujuan
Memberikan kemampuan kepada pengguna untuk secara paksa memicu pembaruan koneksi dan data dari antarmuka aplikasi dengan menarik layar ke bawah (pull-to-refresh). Hal ini sangat berguna jika data MQTT dirasa tidak memperbarui secara real-time akibat gangguan jaringan sementara di perangkat mobile.

### B. Spesifikasi Alur Kerja
* **Halaman Dashboard** ([dashboard_page.dart](file:///d:/SEMESTER%204/PPL/aplikasi/HydroSense-PPL-Agro-C2/lib/screens/dashboard_page.dart)):
  * Membungkus daftar kartu meja dalam widget `RefreshIndicator`.
  * Saat ditarik, aplikasi akan menjalankan fungsi:
    1. Memanggil `_mqttController.reconnect()` untuk menyambung ulang broker MQTT.
    2. Memaksa pembacaan ulang rujukan Firebase Realtime Database untuk status batas parameter terbaru (`device_settings`).
* **Halaman Detail** ([detail_page.dart](file:///d:/SEMESTER%204/PPL/aplikasi/HydroSense-PPL-Agro-C2/lib/screens/detail_page.dart)):
  * Membungkus tab pemantauan (*Monitoring Tab*) dan tab pengaturan (*Setting Tab*) dalam `RefreshIndicator`.
  * Saat ditarik, aplikasi akan:
    1. Memanggil fungsi `_loadSavedSetting()` untuk memuat ulang parameter konfigurasi IoT dari Firebase secara real-time.
    2. Menyegarkan status koneksi MQTT lokal.

---

## 3. Rencana Implementasi Teknis (Flutter/Dart)

### A. Implementasi Gauge tanpa Package Tambahan (Custom Paint)
Untuk menjaga performa aplikasi tetap cepat dan menghindari pembengkakan ukuran file APK (tanpa package eksternal yang berat), kita akan menggunakan `CustomPainter` bawaan Flutter.

Contoh struktur dasar widget `CircularSensorGauge`:
```dart
import 'dart:math';
import 'package:flutter/material.dart';

class CircularSensorGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final double normalMin;
  final double normalMax;
  final String label;
  final String unit;
  final Color activeColor;

  const CircularSensorGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.normalMin,
    required this.normalMax,
    required this.label,
    required this.unit,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(140, 140),
                painter: GaugePainter(
                  value: value,
                  min: min,
                  max: max,
                  normalMin: normalMin,
                  normalMax: normalMax,
                  activeColor: activeColor,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3A34),
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final double normalMin;
  final double normalMax;
  final Color activeColor;

  GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.normalMin,
    required this.normalMax,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 12.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // 1. Gambar cincin background abu-abu tipis
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75, // Mulai dari bawah-kiri
      pi * 1.5,  // Busur 270 derajat
      false,
      bgPaint,
    );

    // 2. Hitung persentase nilai sensor saat ini
    final double clampedValue = value.clamp(min, max);
    final double sweepAngle = ((clampedValue - min) / (max - min)) * (pi * 1.5);

    // 3. Gambar cincin progres sensor dinamis
    final Paint progressPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

### B. Implementasi RefreshIndicator
Di [dashboard_page.dart](file:///d:/SEMESTER%204/PPL/aplikasi/HydroSense-PPL-Agro-C2/lib/screens/dashboard_page.dart):
```dart
RefreshIndicator(
  onRefresh: () async {
    _mqttController.reconnect();
    // Berikan delay sedikit untuk transisi menyegarkan yang memuaskan
    await Future.delayed(const Duration(milliseconds: 800));
  },
  child: ListView.builder(...),
)
```

---

## 4. Rencana Pengujian & Validasi
1. **Verifikasi Visual Gauge**:
   * Memastikan cincin pH berubah warna menjadi merah saat nilai di bawah batas normal atau di atas batas maksimal.
   * Memastikan cincin PPM berubah menjadi merah jika nilai di bawah batas PPM minimal atau di atas maksimal.
2. **Verifikasi Fungsionalitas Refresh**:
   * Melakukan tarikan layar pada Dashboard dan memastikan log pemanggilan koneksi MQTT berjalan.
   * Melakukan tarikan layar pada Detail dan memastikan data sensor terupdate instan dari database.
