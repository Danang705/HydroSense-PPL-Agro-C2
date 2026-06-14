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
      begin: const Offset(0, 0.08),
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

    // Tunggu durasi minimal animasi splash
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
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [HydroDesign.lightGreenBg, Colors.white],
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
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Brand Label
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: HydroDesign.primaryGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: HydroDesign.primaryGreen,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'HydroSense',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: HydroDesign.primaryGreen,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Large Bold Onboarding Header
                    const Text(
                      'Teman Pintar\nKebun Hidroponik\nAnda.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: HydroDesign.darkText,
                        height: 1.25,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Monitoring hidroponik real-time\ndan otomatisasi dalam genggaman Anda.',
                      style: TextStyle(
                        fontSize: 15,
                        color: HydroDesign.grayText,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/splash_illustration.png',
                          width: 290,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderIllustration();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_checkingAuth)
                      const SizedBox(
                        height: 60,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: HydroDesign.primaryGreen,
                          ),
                        ),
                      )
                    else
                      _buildGetStartedButton(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: HydroDesign.primaryGreen,
        borderRadius: BorderRadius.circular(30),
        boxShadow: HydroDesign.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _goToLogin,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            children: [
              const SizedBox(width: 6),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: HydroDesign.primaryGreen,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 54), // Offset the circle on the left
                    child: Text(
                      'Mulai Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIllustration() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: HydroDesign.lightGreenBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: HydroDesign.primaryGreen.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.eco_rounded,
          size: 120,
          color: HydroDesign.primaryGreen,
        ),
      ),
    );
  }
}