import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_notification.dart';
import '../widgets/hydro_design.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nicknameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final User? user = FirebaseAuth.instance.currentUser;
    _nicknameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final String nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      setState(() {
        _errorMessage = 'Nickname tidak boleh kosong.';
      });
      return;
    }

    if (nickname.length < 3) {
      setState(() {
        _errorMessage = 'Nickname minimal 3 karakter.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User tidak ditemukan',
        );
      }

      await user.updateDisplayName(nickname);
      await FirebaseAuth.instance.currentUser?.reload();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      HydroNotification.showFloatingToast(
        context: context,
        message: 'Nickname berhasil diperbarui',
        isSuccess: true,
        icon: Icons.badge_outlined,
      );

      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memperbarui nickname.';
      });
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'requires-recent-login':
        return 'Silakan login ulang sebelum mengubah nickname.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'user-not-found':
        return 'User tidak ditemukan.';
      default:
        return 'Gagal memperbarui nickname.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HydroDesign.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: HydroDesign.darkText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Nickname',
          style: TextStyle(
            color: HydroDesign.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: HydroDesign.premiumShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: HydroDesign.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: HydroDesign.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Ubah Nickname',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: HydroDesign.darkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nickname akan tampil pada halaman dashboard dan profil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: HydroDesign.grayText,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _buildInputField(
                    label: 'Nickname',
                    controller: _nicknameController,
                    hint: 'Masukkan nickname baru',
                    icon: Icons.badge_outlined,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HydroDesign.dangerRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: HydroDesign.dangerRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveNickname,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HydroDesign.primaryGreen,
                        foregroundColor: Colors.white,
                        shadowColor: HydroDesign.primaryGreen.withValues(alpha: 0.25),
                        elevation: 6,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Simpan Nickname',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: HydroDesign.grayText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isLoading) {
              _saveNickname();
            }
          },
          style: const TextStyle(
            color: HydroDesign.darkText,
            fontWeight: FontWeight.w600,
          ),
          decoration: HydroDesign.inputStyle(
            hintText: hint,
            prefixIcon: icon,
          ),
        ),
      ],
    );
  }
}