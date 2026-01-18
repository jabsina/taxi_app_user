import 'package:flutter/material.dart';
import 'package:taxi_app_user/screen/loginscreen.dart';
import 'package:taxi_app_user/screen/main_screen.dart';
import 'package:taxi_app_user/screen/splash_screen.dart';
import '../services/secure_storage_service.dart';

import 'home_page.dart';

class AuthcheckScreen extends StatefulWidget {
  const AuthcheckScreen({super.key});

  @override
  State<AuthcheckScreen> createState() => _AuthcheckScreenState();
}

class _AuthcheckScreenState extends State<AuthcheckScreen> {

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    bool loggedIn = await SecureStorageService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedPage()),
      );
    }
  }

  // ✅ THIS WAS MISSING
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

