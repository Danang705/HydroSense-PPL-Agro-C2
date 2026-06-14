# Product Requirements Document (PRD) - Overhaul UI/UX Modernisasi HydroSense

Dokumen ini mendefinisikan panduan dan kebutuhan spesifik untuk merombak total antarmuka (UI) dan pengalaman pengguna (UX) aplikasi **HydroSense**. Perubahan difokuskan murni pada sisi visual (tata letak, dekorasi, tipografi, dan mikro-interaksi) untuk menghilangkan kesan "kaku" dan menggantikannya dengan desain modern kelas dunia (*state-of-the-art*).

*Penting: Seluruh logika bisnis, nama parameter, database Firebase, dan topic komunikasi MQTT tetap dipertahankan tanpa perubahan.*

---

## 1. Konsep & Filosofi Desain Baru
Untuk menghadirkan antarmuka modern yang dinamis namun tetap fungsional bagi pemantauan kebun, desain baru akan mengadopsi 4 pilar utama:
1. **Premium Glassmorphism & Soft Shadow**: 
   * Menggunakan sudut membulat lebar (radius `20px` - `32px`).
   * Menghilangkan border keras (solid outline) dan menggantinya dengan bayangan super lembut (*super soft drop shadow* dengan blur radius tinggi `24px` - `32px` dan opacity rendah `3%` - `5%`).
2. **Input Fields Kontainer (Bukan Underline)**:
   * Mengganti input field gaya lama (garis bawah/divider) dengan boks kontainer melengkung (`BorderRadius.circular(16)`).
   * Latar belakang boks menggunakan abu-abu/hijau pucat lembut (`#F8F9FA` atau `#F0F4F2`) yang akan bertransisi ke garis hijau botani menyala saat fokus aktif (*focused border*).
3. **Tipografi Dinamis & Bernapas (Whitespace)**:
   * Menambahkan jarak (*padding & margin*) yang lebih lega antar elemen untuk memberikan ruang bernapas pada layar (menghilangkan kesan padat/berdesakan).
   * Memaksimalkan font bawaan proyek (Nunito/Inter) dengan variasi ketebalan (*FontWeight.w900* untuk judul besar, *letter-spacing: -0.5* untuk kesan modern).
4. **Mikro-Interaksi & Kontrol Taktil (Tactile Controls)**:
   * Menambahkan umpan balik visual saat tombol ditekan (seperti efek pencet/skala mikro).
   * Menggantikan ketikan keyboard untuk pengaturan dosis dengan tombol increment/decrement kontainer (`+` dan `-`) yang melingkari kolom input angka agar terasa seperti kontrol fisik alat.

---

## 2. Rincian Pembaruan per Halaman

### A. Splash Screen (`splash_screen.dart`)
* **Kondisi Lama**: Ilustrasi bulat kaku dengan tombol hijau di bagian bawah.
* **Desain Baru**:
  * Efek latar belakang gradien halus dari hijau mint pucat (`#F0F7F3`) ke putih bersih.
  * Logo atau ilustrasi memiliki efek bayangan melayang lembut.
  * Judul "HydroSense" menggunakan font ekstra tebal (`FontWeight.w900`) dengan aksen hijau botani (`#1E5C3A`).
  * Tombol "Masuk" diubah dengan gradien linear halus (`Color(0xFF1E5C3A)` ke `Color(0xFF2D7A50)`) dengan efek bayangan melayang.

### B. Halaman Login & Lupa Password (`login_page.dart` & `forgot_password_page.dart`)
* **Kondisi Lama**: Kolom masukan menggunakan garis pembatas bawah sederhana yang terasa kaku dan jadul.
* **Desain Baru**:
  * **Boks Masukan Modern**: Input teks email & password berada dalam boks putih melengkung (`BorderRadius.circular(18)`) dengan bayangan sangat lembut.
  * **Indikator Keaktifan**: Saat kolom diklik, boks akan memiliki border hijau botani tipis (`1.5px`) dan ikon di sebelahnya akan menyala hijau.
  * **Tombol Utama**: Menggunakan tombol gradien melengkung penuh (capsule button) dengan bayangan tebal namun transparan.

### C. Halaman Dashboard (`dashboard_page.dart`)
* **Kondisi Lama**: Baris ringkasan data kaku, kartu meja menggunakan garis tepi (border) tipis biasa.
* **Desain Baru**:
  * **Ringkasan Status Terintegrasi**: Kartu summary "Normal" dan "Perlu Perhatian" dibuat lebih melengkung (`BorderRadius.circular(24)`) dengan latar belakang gradien monokromatik lembut.
  * **Kartu Meja Modern (Glass Card)**:
    * Latar belakang kartu menggunakan warna putih bersih dengan bayangan melayang.
    * Status "NORMAL" dan "TIDAK NORMAL" menggunakan warna kapsul solid dengan transparansi tinggi (opacity 12% untuk latar belakang, 100% untuk warna teks).
    * Data baris sensor (pH, Nutrisi, Volume) menggunakan baris ikon melingkar mini di sebelah kiri untuk masing-masing parameter.

### D. Halaman Detail Data Meja (`detail_page.dart`)
* **Kondisi Lama**: Tab bar kaku, pengaturan standar otomatisasi menggunakan input teks keyboard standar.
* **Desain Baru**:
  * **Tab Menu Modern**: Tab bar diletakkan di dalam kontainer abu-abu membulat dengan indikator aktif berupa pil putih melayang (seperti gaya iOS/iPadOS).
  * **Boks Pengaturan Parameter**:
    * Pengaturan batas pH dan PPM menggunakan boks input modern yang disatukan secara simetris dalam satu baris.
    * **Kontrol Dosis Incremental (Increment/Decrement)**: Input teks dosis manual/otomatis diubah menjadi boks angka yang diapit oleh tombol bulat minus (`-`) di kiri dan plus (`+`) di kanan. Pengguna cukup mengetuk tombol untuk menaikkan/menurunkan dosis tanpa perlu memunculkan keyboard virtual (namun ketik manual tetap diizinkan).
  * **Tombol Pompa Manual**:
    * Menggunakan tombol boks membulat 3D yang berubah warna menjadi hijau pekat saat aktif dengan ikon tetesan air/panah yang lebih tebal.

### E. Halaman Profil & Pengeditan (`profile_page.dart`, `edit_profile_page.dart`, `change_password_page.dart`)
* **Kondisi Lama**: Menu list berupa boks berderet berhimpitan dengan garis tepi tipis abu-abu.
* **Desain Baru**:
  * **Bilah Profil Melayang**: Kartu nama profil menggunakan gradien hijau botani modern dengan ikon avatar yang memiliki ring bercahaya lembut (*glow border*).
  * **Grup Menu Terpisah**: Menu list dipisah dengan jarak (*margin*) yang proporsional. Setiap baris memiliki ikon berwarna hijau botani di dalam lingkaran bulat halus (`Color(0xFFE6F2F0)`).
  * Menghilangkan garis pembatas abu-abu keras dan menggantinya dengan pemisah visual berbasis bayangan atau ruang putih.

---

## 3. Skema Token & Konstanta UI Baru (Flutter/Dart)

Untuk mempermudah dan menyeragamkan desain baru di semua halaman, kita akan mendefinisikan skema dekorasi standar berikut:

```dart
import 'package:flutter/material.dart';

class HydroDesign {
  // Palet Warna Utama
  static const Color primaryGreen = Color(0xFF1E5C3A);
  static const Color secondaryGreen = Color(0xFF2D7A50);
  static const Color lightGreenBg = Color(0xFFF0F7F3);
  static const Color background = Color(0xFFF4F6F5);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color grayText = Color(0xFF718096);
  static const Color dangerRed = Color(0xFFE54D50);
  static const Color warningOrange = Color(0xFFDD6B20);
  static const Color infoTeal = Color(0xFF38B2AC);

  // Bayangan Lembut Premium (Soft Shadows)
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryGreen.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 6),
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
      prefixIcon: Icon(prefixIcon, color: primaryGreen.withValues(alpha: 0.7)),
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
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.08), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }
}
```

---

## 4. Langkah Implementasi
1. **Langkah 1**: Membuat file token desain `lib/widgets/hydro_design.dart` untuk menampung konstanta bayangan, warna gradien, dan style input seragam.
2. **Langkah 2**: Memperbarui Halaman Splash dan Login/Lupa Password dengan kontainer input melengkung dan tombol gradien.
3. **Langkah 3**: Merombak tampilan Dashboard untuk menggunakan Glassmorphic cards dengan visual status pill modern.
4. **Langkah 4**: Memperbarui halaman detail, mengintegrasikan widget counter increment/decrement (`+` / `-`) pada input parameter dosis, serta melapis tab bar dengan gaya pil melayang.
5. **Langkah 5**: Menghias profil card dan menu items di halaman profil agar lebih bersih dan memiliki ruang sela (*whitespace*) yang memadai.
