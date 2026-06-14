# Product Requirements Document (PRD) - Pembaruan UI/UX Notifikasi & Pop-up HydroSense

Dokumen ini mendefinisikan kebutuhan pengembangan untuk memperbarui sistem notifikasi dan pop-up (dialog/snackbar/toast) di dalam aplikasi Flutter **HydroSense**. Pembaruan ini bertujuan untuk meningkatkan interaktivitas, estetika visual, serta memberikan umpan balik (feedback) yang lebih responsif dan informatif kepada pengguna.

---

## 1. Ringkasan Proyek
Aplikasi HydroSense saat ini menggunakan notifikasi dasar bawaan Flutter (seperti default `AlertDialog` dan `SnackBar` sederhana) untuk memberi tahu pengguna tentang peristiwa penting seperti masuk (login), perubahan pengaturan, perubahan profil, dan status pompa manual. 

Pembaruan ini akan mendesain ulang sistem umpan balik visual ini menggunakan prinsip desain modern (warna harmonis, sudut membulat, ikonografi yang jelas, dan mikro-animasi) serta mengusulkan beberapa area kritis baru yang memerlukan penambahan notifikasi pop-up demi kenyamanan dan keselamatan operasional kebun hidroponik.

---

## 2. Analisis Kondisi Saat Ini

Berdasarkan analisis terhadap codebase aplikasi HydroSense, berikut adalah titik komunikasi pengguna saat ini:
1. **Login (`login_page.dart`)**: Menggunakan `showDialog` dengan Material `AlertDialog` abu-abu standar untuk pesan "Login Berhasil" dengan tombol "LANJUT". Tampilannya kaku dan kurang mencerminkan estetika modern.
2. **Kirim Pengaturan ke IoT (`detail_page.dart`)**: Menggunakan `SnackBar` bawaan dengan latar hijau tua (`Color(0xFF1E3A34)`) untuk sukses, dan merah untuk error.
3. **Pompa Manual AB Mix/pH (`detail_page.dart`)**: Langsung memicu aksi kirim data MQTT dan menampilkan `SnackBar` sukses tanpa adanya konfirmasi pengaman. Hal ini berisiko jika pengguna tidak sengaja menekan tombol pompa manual.
4. **Edit Profil/Ubah Password (`edit_profile_page.dart` & `change_password_page.dart`)**: Menggunakan `SnackBar` dasar untuk sukses, dan kontainer merah inline untuk menampilkan error.
5. **Lupa Password (`forgot_password_page.dart`)**: Menggunakan `SnackBar` hijau standar untuk mengonfirmasi bahwa tautan reset password telah terkirim.

---

## 3. Rekomendasi Penempatan Notifikasi Pop-up Baru & Pembaruan

Berikut adalah rekomendasi penempatan notifikasi pop-up/dialog yang dikelompokkan berdasarkan tingkat urgensi dan interaksi pengguna:

### A. Pop-up Konfirmasi Tindakan (High Urgency - Modal Dialog)
Digunakan untuk tindakan yang memiliki dampak fisik pada perangkat IoT atau akun pengguna. Membutuhkan persetujuan eksplisit.

| Lokasi / Fitur | Jenis Pop-up | Isi Pesan / Detail Desain | Rationale (Alasan) |
| :--- | :--- | :--- | :--- |
| **Pompa Manual AB Mix / pH Up / pH Down** (`detail_page.dart`) | **Confirmation Dialog** | *"Apakah Anda yakin ingin menyalakan Pompa [Nama Pompa] secara manual sebesar [X] ml?"* dengan tombol **Batal** dan **Jalankan**. | **Mencegah Overdosis Cairan:** Pompa fisik akan mengeluarkan cairan asli ke tangki tanaman. Kesalahan tekan dapat merusak ekosistem hidroponik jika dosis terlalu tinggi. |
| **Keluar Akun (Logout)** (`profile_page.dart` & `dashboard_page.dart`) | **Confirmation Dialog (Destructive)** | *"Yakin ingin keluar?"* dengan tombol **Batal** dan **Keluar** (berwarna merah bahaya). | Mencegah pengguna keluar secara tidak sengaja dan harus mengetik ulang kredensial. |

### B. Pop-up Sukses/Gagal Transisi (Medium Urgency - Animated Dialog / Custom Banner)
Digunakan ketika proses krusial selesai dilakukan dan pengguna membutuhkan kepuasan visual (gratifikasi) bahwa proses tersebut berhasil.

| Lokasi / Fitur | Jenis Pop-up | Isi Pesan / Detail Desain | Rationale (Alasan) |
| :--- | :--- | :--- | :--- |
| **Masuk Akun (Login)** (`login_page.dart`) | **Success Dialog (Auto-Dismiss / Lottie Animated)** | Ilustrasi centang hijau animasi lembut, tulisan *"Masuk Berhasil"*, sub-teks *"Selamat datang kembali di HydroSense!"*. Dapat otomatis menutup atau dialihkan dalam 1.5 detik. | Memberikan kesan premium dan modern saat pengguna pertama kali berinteraksi dengan aplikasi. |
| **Kirim Standar ke IoT** (`detail_page.dart`) | **Success Toast / Custom Bottom Alert** | Ikon cloud/wifi hijau berkilau, tulisan *"Konfigurasi IoT Diperbarui!"*. | Memastikan pengguna tahu bahwa batas pH/PPM baru berhasil disinkronkan ke cloud Firebase & broker MQTT. |

### C. Notifikasi Real-time Sensor Warning (Critical Alert - Banner / Overlay Toast)
Pemberitahuan instan ketika aplikasi sedang terbuka dan mendeteksi kondisi darurat pada meja kebun.

| Lokasi / Fitur | Jenis Pop-up | Isi Pesan / Detail Desain | Rationale (Alasan) |
| :--- | :--- | :--- | :--- |
| **Peringatan Kondisi Meja Tidak Normal** (`dashboard_page.dart` & `detail_page.dart`) | **Floating Alert Banner** (Top of Screen) | *"Peringatan: pH di [Nama Meja] di luar batas aman! (Sensor: 4.8 pH, Batas Min: 5.5 pH)."* | Memberikan respons instan agar pengguna dapat langsung memantau meja bersangkutan sebelum tanaman layu. |
| **Koneksi MQTT Terputus** (`dashboard_page.dart`) | **Sticky Status Banner** (Yellow/Orange Alert) | *"Koneksi terputus. Menghubungkan kembali ke server IoT..."* dengan ikon putus dan tombol **Coba Lagi**. | Menghindari kebingungan pengguna saat data sensor tidak berubah karena masalah jaringan. |

### D. Notifikasi Operasional Ringan (Low Urgency - Modern Floating SnackBar)
Umpan balik cepat untuk tindakan konfigurasi profil.

| Lokasi / Fitur | Jenis Pop-up | Isi Pesan / Detail Desain | Rationale (Alasan) |
| :--- | :--- | :--- | :--- |
| **Pembaruan Nickname** (`edit_profile_page.dart`) | **Floating Toast / Custom SnackBar** | *"Nama tampilan berhasil diubah menjadi [Nama Baru]."* dengan ikon profil centang. | Konfirmasi ringan bahwa data lokal dan Firebase Auth sinkron. |
| **Ubah Password** (`change_password_page.dart`) | **Floating Toast / Custom SnackBar** | *"Password berhasil diperbarui secara aman."* dengan ikon gembok hijau. | Menandakan penyelesaian pengaturan keamanan. |
| **Tautan Reset Password Terkirim** (`forgot_password_page.dart` / `profile_page.dart`) | **Actionable SnackBar / Dialog** | *"Tautan dikirim ke [Email]!"* dengan tombol pintasan **Buka Email** (membuka aplikasi Gmail/Outlook). | Mempermudah pengguna langsung memverifikasi kotak masuk email mereka. |

---

## 4. Spesifikasi Desain Antarmuka Notifikasi (UI/UX Guidelines)

Untuk menciptakan tampilan premium yang sejalan dengan identitas visual **HydroSense** (hijau botani, modern, bersih), sistem notifikasi baru harus mengikuti aturan desain berikut:

1. **Palet Warna**:
   * **Success**: Latar belakang putih dengan aksen hijau tua (`#1E5C3A` atau `#2D7A50`) dan bayangan lembut.
   * **Warning/Danger**: Latar belakang putih dengan aksen merah lembut (`#E54D50` atau `#DC2626`) untuk menarik perhatian tanpa terlihat terlalu kasar.
   * **Info/Connection**: Latar belakang putih dengan aksen biru teal (`#38B2AC`) atau oranye hangat untuk status reconnecting.
2. **Tipografi**:
   * Menggunakan hierarki font yang jelas: Judul tebal (Bold, 16-18px) untuk status utama, deskripsi reguler (Regular, 12-14px) untuk rincian informasi.
3. **Bentuk (Shape)**:
   * Menghindari sudut tajam. Semua kartu pop-up dan dialog wajib memiliki radius sudut (`BorderRadius.circular(20)` hingga `24`).
4. **Efek Mikro-Animasi**:
   * Menggunakan transisi masuk halus (seperti *scale transition* atau *slide transition* dari atas/bawah) untuk menghindari pop-up yang muncul secara mendadak.

---

## 5. Rencana Implementasi Teknis (Flutter/Dart)

### Pendekatan Arsitektur Kode:
Untuk mencegah penulisan ulang kode berulang di setiap file screen, disarankan membuat satu helper class utility khusus untuk notifikasi: `NotificationHelper` atau `HydroNotification`.

Contoh rancangan struktur kelas utilitas di Flutter:

```dart
import 'package:flutter/material.dart';

class HydroNotification {
  // 1. Pop-up Konfirmasi Tindakan Pompa/Logout (Modal Dialog)
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'YA, JALANKAN',
    String cancelText = 'BATAL',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
                color: isDestructive ? const Color(0xFFE54D50) : const Color(0xFF1E5C3A),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? const Color(0xFFE54D50) : const Color(0xFF1E3A34),
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                cancelText,
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? const Color(0xFFE54D50) : const Color(0xFF1E5C3A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // 2. Custom SnackBar / Toast Melayang (Sukses / Gagal)
  static void showFloatingToast({
    required BuildContext context,
    required String message,
    required bool isSuccess,
    IconData? icon,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.removeCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: isSuccess ? const Color(0xFF1E5C3A).withOpacity(0.2) : const Color(0xFFE54D50).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFFE6F2F0) : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? (isSuccess ? Icons.check_circle_outline : Icons.error_outline),
                  color: isSuccess ? const Color(0xFF1E5C3A) : const Color(0xFFE54D50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 6. Penutup & Prioritas Pengembangan
* **Prioritas Utama (P1)**:
  * Mengganti popup login default menjadi dialog sukses teranimasi.
  * Menambahkan dialog konfirmasi pada tombol Pompa Manual di `detail_page.dart` demi keselamatan ekosistem kebun.
* **Prioritas Kedua (P2)**:
  * Mengubah snackbar standar pada halaman edit profil, ubah password, dan simpan pengaturan standar menjadi model *floating toast* melayang.
* **Prioritas Ketiga (P3)**:
  * Implementasi sistem banner MQTT connection status offline, serta in-app alert banner jika sensor melewati ambang batas aman.
