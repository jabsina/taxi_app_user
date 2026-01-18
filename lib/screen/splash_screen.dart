import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_app_user/screen/authcheck_page.dart';
import 'loginscreen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return; // ✅ IMPORTANT

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthcheckScreen(),
        ),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animations/car_loading.json',
          width: 220,
          repeat: true,
        ),
      ),
    );
  }
}
