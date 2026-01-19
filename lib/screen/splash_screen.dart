import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_app_user/screen/authcheck_page.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ Wait until FIRST FRAME is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AuthcheckScreen(),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // ✅ MATCH Android splash + app background
      backgroundColor: Colors.white,

      body: Center(
        child: SizedBox(
          width: 220,
          child: _SplashLottie(),
        ),
      ),
    );
  }
}

class _SplashLottie extends StatelessWidget {
  const _SplashLottie();

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/car_loading.json',
      repeat: true,
      fit: BoxFit.contain,
    );
  }
}
