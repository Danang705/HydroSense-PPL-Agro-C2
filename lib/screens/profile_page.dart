import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_notification.dart';
import '../widgets/hydro_design.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isSendingPasswordReset = false;

  String _getDisplayName(User? user) {
    final String? displayName = user?.displayName;

    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    final String? email = user?.email;

    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Pengguna HydroSense';
  }

  String _getEmail(User? user) {
    return user?.email ?? 'Email tidak tersedia';
  }

  String _getResetPasswordErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Email belum terdaftar.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti.';
      default:
        return 'Gagal mengirim tautan reset password.';
    }
  }

  Future<void> _openEditProfile(BuildContext context) async {
    await Navigator.pushNamed(context, '/edit_profile');

    final User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _sendPasswordResetLink(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email;

    if (email == null || email.trim().isEmpty) {
      HydroNotification.showFloatingToast(
        context: context,
        message: 'Email akun tidak ditemukan.',
        isSuccess: false,
      );
      return;
    }

    final bool confirm = await HydroNotification.showConfirmDialog(
      context: context,
      title: 'Reset Password',
      message: 'Apakah kamu yakin ingin mengirim tautan reset password ke email berikut?\n\n$email',
      confirmText: 'KIRIM',
      cancelText: 'BATAL',
    );

    if (!confirm) return;

    setState(() {
      _isSendingPasswordReset = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );

      if (!context.mounted) return;

      HydroNotification.showFloatingToast(
        context: context,
        message: 'Tautan reset password telah dikirim ke $email',
        isSuccess: true,
        icon: Icons.mail_outline_rounded,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      HydroNotification.showFloatingToast(
        context: context,
        message: _getResetPasswordErrorMessage(e.code),
        isSuccess: false,
      );
    } catch (_) {
      if (!context.mounted) return;

      HydroNotification.showFloatingToast(
        context: context,
        message: 'Terjadi kesalahan tidak terduga.',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingPasswordReset = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
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

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final User? user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        final String displayName = _getDisplayName(user);
        final String email = _getEmail(user);

        return Scaffold(
          backgroundColor: HydroDesign.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: HydroDesign.darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kelola informasi akun HydroSense Anda.',
                  style: TextStyle(
                    fontSize: 13,
                    color: HydroDesign.grayText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                _buildProfileCard(
                  displayName: displayName,
                  email: email,
                ),
                const SizedBox(height: 24),
                _buildMenuCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profil',
                  subtitle: 'Ubah nama tampilan akun',
                  onTap: () {
                    _openEditProfile(context);
                  },
                ),
                const SizedBox(height: 14),
                _buildMenuCard(
                  icon: Icons.lock_reset_rounded,
                  title: _isSendingPasswordReset
                      ? 'Mengirim Tautan...'
                      : 'Reset Password',
                  subtitle: 'Kirim tautan reset password ke email akun',
                  onTap: _isSendingPasswordReset
                      ? null
                      : () {
                          _sendPasswordResetLink(context);
                        },
                  trailingLoading: _isSendingPasswordReset,
                ),
                const SizedBox(height: 14),
                _buildMenuCard(
                  icon: Icons.email_outlined,
                  title: 'Email Akun',
                  subtitle: email,
                  onTap: null,
                ),
                const SizedBox(height: 32),
                _buildLogoutButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard({
    required String displayName,
    required String email,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HydroDesign.primaryGreen, HydroDesign.secondaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: HydroDesign.primaryGreen.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool trailingLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: HydroDesign.premiumShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: HydroDesign.lightGreenBg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: HydroDesign.primaryGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: HydroDesign.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: HydroDesign.grayText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: HydroDesign.primaryGreen,
                ),
              )
            else if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Keluar Akun',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: HydroDesign.dangerRed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}