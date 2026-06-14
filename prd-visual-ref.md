# Product Requirements Document (PRD) - Pembaruan UI Berdasarkan Referensi FitBite

Dokumen ini mendefinisikan panduan dan kebutuhan spesifik untuk memperbarui total antarmuka (UI) aplikasi **HydroSense** agar selaras dengan estetika modern, segar, dan premium dari gambar referensi yang dikirimkan (berbasis tema aplikasi kesehatan *FitBite*).

---

## 1. Konsep & Filosofi Desain Baru (FitBite Theme)

Untuk menyelaraskan UI HydroSense dengan gambar referensi, kita akan menerapkan 5 pilar desain berikut:
1. **Palet Warna "Fresh Lime & Apple Green"**:
   * Mengganti hijau botani tua (`#1E5C3A`) dengan tema hijau jeruk nipis/apel segar yang cerah dan modern.
   * **Warna Utama (Primary)**: `Color(0xFF65A30D)` (Hijau apel pekat untuk teks penting dan tombol aktif agar kontras keterbacaan tetap terjaga).
   * **Warna Aksen Terang (Accent Highlight)**: `Color(0xFF84CC16)` (Hijau lime menyala untuk elemen dekorasi, indikator aktif, dan status sukses).
   * **Latar Belakang Ringan (Light Background)**: `Color(0xFFF1F8E9)` atau `Color(0xFFECFDF5)` untuk boks kontainer highlight.
   * **Warna Dasar Aplikasi (Background)**: `Color(0xFFF9FAFB)` (Abu-abu sangat muda bersih) dengan kartu putih murni (`#FFFFFF`).
2. **Pola Kartu Bersih Tanpa Batas Fisik (Border-Free Premium Cards)**:
   * Seluruh kartu parameter dan ringkasan menggunakan radius membulat yang lebih besar (`BorderRadius.circular(24)` atau `28`).
   * Menghilangkan garis tepi padat (border) dan menggunakan warna latar putih solid di atas background abu-abu muda dengan bayangan yang sangat tipis dan halus (`Colors.black.withValues(alpha: 0.02)`).
3. **Tipografi Bersih & Lapang (Whitespace)**:
   * Menggunakan ketebalan judul `FontWeight.w900` atau `FontWeight.w800`.
   * Menampilkan angka data dengan font ukuran besar dan tebal (misalnya nilai sensor pH dan PPM di Dashboard/Detail).
4. **Layout Grid Simetris & Strip Kalender Horizontal**:
   * Mengadopsi tata letak grid 2-kolom untuk menampilkan metrik ringkasan status kebun.
   * Menambahkan komponen visual **Horizontal Calendar Strip** di halaman dashboard untuk menunjukkan hari aktif dalam minggu berjalan.
5. **Splash Screen Onboarding Terstruktur**:
   * Menyesuaikan Splash Screen agar meniru gaya layar pertama di referensi: teks tebal di atas, gambar/ilustrasi tanaman hydroponik besar di bagian bawah, dan tombol aksi "Get Started" kapsul lebar di bawahnya.

---

## 2. Rincian Pembaruan per Halaman

### A. Halaman Splash/Onboarding (`splash_screen.dart`)
* **Desain Baru**:
  * **Bagian Atas**: Teks judul tebal `"Teman Pintar Kebun Hidroponik Anda."` menggunakan font ukuran besar (`fontSize: 32`, `FontWeight.w900`) dengan logo kecil HydroSense.
  * **Bagian Tengah ke Bawah**: Ilustrasi grafis tanaman atau gambar kebun hidroponik yang bersih dan melayang (tanpa frame bulat kaku).
  * **Bagian Bawah**: Tombol `"Mulai Sekarang"` berbentuk kapsul melengkung penuh berwarna lime hijau segar dengan ikon panah melingkar di sisi kiri tombol.

### B. Halaman Dashboard (`dashboard_page.dart`)
* **Desain Baru**:
  * **Header Profil**: Menggunakan tata letak baris melayang: Avatar pengguna melingkar di kiri, sapaan `"Selamat Pagi!"` dan nama pengguna `"Danang"` di tengah, serta tombol ikon kalender & notifikasi melayang di kanan.
  * **Highlight Banner Card**: Kartu banner hijau apel muda (`Color(0xFFECFDF5)`) bertuliskan `"Kondisi Kebun Mingguan"` atau `"Performa Kebun Anda"` dengan grafik progress melingkar (gauge) mini yang menunjukkan persentase kestabilan kebun.
  * **Grid Ringkasan (2 Column Summary)**:
    * Mengubah baris status "Normal" dan "Perlu Perhatian" menjadi grid 2-kolom berdampingan yang simetris.
    * Masing-masing dihiasi ikon mini berlatar belakang lingkaran pastel lembut.
  * **Horizontal Calendar Strip**:
    * Menambahkan baris penanggalan hari berjalan dalam minggu ini (contoh: S, M, T, W, T, F, S) di bawah grid ringkasan.
    * Hari ini (aktif) akan disorot dengan kapsul berwarna hijau lime terang (`Color(0xFF84CC16)`) dengan teks putih tebal.
  * **List Meja Real-Time**:
    * Kartu meja diubah menjadi lebih ringkas dengan sudut membulat lebar `24`.
    * Menggunakan status pill "NORMAL" dengan latar belakang hijau muda segar transparan dan teks hijau pekat.
    * Di kanan kartu meja, terdapat tombol bulat dengan ikon `+` atau `>` untuk masuk ke detail meja (meniru gaya list item FitBite).

### C. Halaman Detail Data Meja (`detail_page.dart`)
* **Desain Baru**:
  * **Visual Sensor Card**:
    * Menyusun indikator gauge sensor (pH, PPM, Volume) di dalam kartu-kartu putih dengan radius `24` berbayangan sangat lembut.
    * Warna aktif ring sensor disesuaikan menggunakan warna lime green cerah (`Color(0xFF84CC16)`) saat normal, dan oranye/merah saat warning.
  * **Input & Control Fields**:
    * Tombol increment/decrement dosis (`+` dan `-`) menggunakan warna hijau jeruk nipis segar (`Color(0xFFD9F99D)` untuk latar belakang, dan `Color(0xFF65A30D)` untuk ikon).
    * Boks input minimal/maksimal parameter batas dirapikan dengan warna pengisi boks abu-abu sangat muda bersih.
  * **Manual Pump Action Buttons**:
    * Didesain ulang menggunakan warna dasar putih dengan bayangan premium dan border hijau tipis, atau menggunakan warna gradien hijau lime segar (`Color(0xFF84CC16)` ke `Color(0xFF65A30D)`) yang membulat penuh.

### D. Halaman Profil & Edit Akun (`profile_page.dart` & `edit_profile_page.dart` & `change_password_page.dart`)
* **Desain Baru**:
  * Profil header menggunakan warna dasar putih bersih atau gradien lime green yang lebih cerah.
  * Ikon pada daftar baris menu menggunakan pembungkus lingkaran pastel dengan warna lime green muda (`Color(0xFFF1F8E9)`).
  * Tombol utama dan input boks diubah agar seragam dengan warna primer hijau apel baru (`Color(0xFF65A30D)`).

---

## 3. Skema Token & Konstanta UI Baru (Flutter/Dart)

Kita akan memperbarui `lib/widgets/hydro_design.dart` dengan skema warna FitBite baru:

```dart
import 'package:flutter/material.dart';

class HydroDesign {
  // Palet Warna FitBite Theme
  static const Color primaryGreen = Color(0xFF65A30D); // Hijau Apel Pekat (High contrast)
  static const Color secondaryGreen = Color(0xFF84CC16); // Hijau Lime Menyala (Highlight)
  static const Color lightGreenBg = Color(0xFFF1F8E9); // Latar Belakang Hijau Lime Lembut
  static const Color accentGreenHighlight = Color(0xFFECFDF5); // Hijau Mint Sangat Terang
  static const Color background = Color(0xFFF9FAFB); // Latar Belakang Abu-Abu Bersih
  static const Color darkText = Color(0xFF1F2937); // Hitam Charcoal
  static const Color grayText = Color(0xFF6B7280); // Abu-Abu Sedang
  static const Color dangerRed = Color(0xFFEF4444); // Merah Terang
  static const Color warningOrange = Color(0xFFF97316); // Oranye
  static const Color infoTeal = Color(0xFF06B6D4); // Teal

  // Bayangan Lembut Premium FitBite (Ultra Soft Shadows)
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryGreen.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // Dekorasi Input Teks Modern
  static InputDecoration inputStyle({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: primaryGreen.withValues(alpha: 0.6)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.05), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }
}
```
