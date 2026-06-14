import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/hydro_design.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.7,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.2,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _controller.forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final User? user = FirebaseAuth.instance.currentUser;

    // Tunggu durasi minimal animasi splash agar transisi visual tetap estetik
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F7F3), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/splash_illustration.png',
                        width: 280,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderIllustration();
                        },
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      const Text(
                        'HydroSense',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E5C3A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitoring hidroponik real-time\ndari genggaman Anda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  if (_checkingAuth)
                    const SizedBox(
                      height: 58,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E5C3A),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: HydroDesign.buttonShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: _goToLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E5C3A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIllustration() {
    return Container(
      width: 240,
      height: 240,
      decoration: const BoxDecoration(
        color: Color(0xFFD4EDE0),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.eco,
        size: 120,
        color: Color(0xFF1E5C3A),
      ),
    );
  }
}