# Product Requirements Document (PRD) - Autentikasi Persisten & Auto-Login HydroSense

Dokumen ini mendefinisikan kebutuhan pengembangan untuk fitur Autentikasi Persisten (Keep-Me-Logged-In) di aplikasi **HydroSense**. Fitur ini memastikan bahwa pengguna yang telah sukses masuk (login) tidak perlu memasukkan kredensial mereka kembali ketika membuka aplikasi di kemudian hari, kecuali mereka secara eksplisit keluar (logout).

---

## 1. Ringkasan Fitur
Tujuan utama fitur ini adalah meningkatkan kenyamanan pengguna (*user retention & friction reduction*). Saat aplikasi dibuka pertama kali (pada *Splash Screen*), sistem akan mendeteksi status sesi pengguna secara asinkron. 
- Jika pengguna **sudah masuk sebelumnya**, aplikasi akan langsung mengarahkan pengguna ke halaman **Dashboard** setelah animasi Splash selesai.
- Jika pengguna **belum masuk**, aplikasi akan tetap berada pada halaman Splash dan menampilkan tombol **Masuk** menuju halaman login seperti biasa.

---

## 2. Analisis Alur Saat Ini (Current Flow)

Saat ini, alur pembukaan aplikasi selalu mewajibkan interaksi manual:
1. Pengguna membuka aplikasi -> Masuk ke `SplashScreen`.
2. Halaman `SplashScreen` selesai beranimasi, tetapi tertahan dan mewajibkan pengguna menekan tombol **Masuk**.
3. Tombol **Masuk** selalu mengarahkan ke rute `/login`.
4. Firebase Auth secara default menyimpan sesi pengguna secara lokal di perangkat, namun aplikasi saat ini tidak pernah membaca status `FirebaseAuth.instance.currentUser` pada saat pembukaan awal di `SplashScreen`.

---

## 3. Spesifikasi Kebutuhan & Desain Alur Baru (Proposed Flow)

```
       [ Aplikasi Dibuka ]
                |
                v
       ( Splash Screen )
      Mulai Animasi (1.5s)
   Cek FirebaseAuth.currentUser
                |
        +-------+-------+
        |               |
   (Ada Sesi)      (Tidak Ada)
        |               |
        v               v
   Tunggu Animasi    Tetap Tampil
      Selesai        Tombol Masuk
        |               |
        v               v
   Navigasi ke     Navigasi Manual
   /dashboard       ke /login
```

### Kebutuhan Fungsional:
1. **Deteksi Sesi Otomatis**:
   * Membaca properti `FirebaseAuth.instance.currentUser` secara asinkron saat `SplashScreen` diinisialisasi.
2. **Navigasi Bersyarat**:
   * Jika sesi aktif ditemukan (`currentUser != null`), sistem akan menunda navigasi selama 1.5 - 2 detik (menunggu animasi logo splash selesai berputar/muncul) lalu melakukan `Navigator.pushReplacementNamed(context, '/dashboard')`.
   * Jika sesi kosong, tombol "Masuk" akan tetap ditampilkan di layar untuk memungkinkan login manual.
3. **Pembersihan Sesi pada Logout**:
   * Saat melakukan logout di [profile_page.dart](file:///d:/SEMESTER%204/PPL/aplikasi/HydroSense-PPL-Agro-C2/lib/screens/profile_page.dart) atau [dashboard_page.dart](file:///d:/SEMESTER%204/PPL/aplikasi/HydroSense-PPL-Agro-C2/lib/screens/dashboard_page.dart), pemicu `FirebaseAuth.instance.signOut()` akan menghapus sesi lokal sehingga pada pembukaan aplikasi selanjutnya pengguna akan diarahkan kembali ke Splash/Login secara benar.

---

## 4. Spesifikasi Implementasi Teknis (Flutter/Dart)

### Perubahan pada [splash_screen.dart](file:///d:/SEMESTER%204/PPL/aplikasi/HydroSense-PPL-Agro-C2/lib/screens/splash_screen.dart):
Kita akan memodifikasi `_SplashScreenState` sebagai berikut:
- Menambahkan pengecekan status login di `initState`.
- Mengatur variabel `_isLoggedIn` berdasarkan status `FirebaseAuth.instance.currentUser`.
- Jika `_isLoggedIn == true`, kita jalankan `Future.delayed` selama durasi animasi (misal 1500ms) untuk mengarahkan pengguna secara otomatis ke `/dashboard`.
- Di dalam tampilan UI, tombol "Masuk" hanya akan ditampilkan jika `_isLoggedIn == false` (atau disembunyikan agar tampilan bersih selama transisi otomatis).

Contoh rancangan kode logika transisi otomatis:
```dart
bool _isLoggedIn = false;
bool _checkingAuth = true;

@override
void initState() {
  super.initState();
  _controller = AnimationController(...);
  // ... inisialisasi animasi lainnya ...
  
  _checkAuthAndNavigate();
}

Future<void> _checkAuthAndNavigate() async {
  // Cek status autentikasi dari Firebase
  final user = FirebaseAuth.instance.currentUser;
  
  setState(() {
    _isLoggedIn = user != null;
    _checkingAuth = false;
  });

  if (_isLoggedIn) {
    // Jika sudah masuk, tunggu animasi splash selesai lalu redirect ke dashboard
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }
}
```

---

## 5. Rencana Verifikasi (Verification Plan)
1. **Skenario Pengguna Baru / Belum Login**:
   * Buka aplikasi -> Pastikan Splash screen berhenti dan menampilkan tombol "Masuk". Tekan tombol -> Diarahkan ke halaman login.
2. **Skenario Pengguna Sudah Login**:
   * Buka aplikasi -> Masukkan email & password -> Login Berhasil.
   * Keluar dari aplikasi (close/kill app dari task manager).
   * Buka kembali aplikasi -> Pastikan aplikasi menampilkan animasi Splash Screen lalu **otomatis masuk ke Dashboard** tanpa menekan tombol "Masuk" dan tanpa mengisi form login kembali.
3. **Skenario Setelah Logout**:
   * Di halaman Dashboard/Profil, tekan tombol "Keluar Akun" -> Setujui konfirmasi keluar.
   * Keluar dari aplikasi (close/kill app).
   * Buka kembali aplikasi -> Pastikan aplikasi tertahan di Splash Screen dan menampilkan tombol "Masuk" (sesi lama terhapus dengan benar).
