import 'package:flutter/material.dart';
import 'package:taxi_app_user/screen/loginscreen.dart';
import 'package:taxi_app_user/screen/main_screen.dart';
import '../services/secure_storage_service.dart';

class AuthcheckScreen extends StatefulWidget {
  const AuthcheckScreen({super.key});

  @override
  State<AuthcheckScreen> createState() => _AuthcheckScreenState();
}

class _AuthcheckScreenState extends State<AuthcheckScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();

    // 🔥 Wait for FIRST FRAME before checking login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLogin();
    });
  }

  Future<void> _checkLogin() async {
    final loggedIn = await SecureStorageService.isLoggedIn();

    if (!mounted) return;

    setState(() => _checking = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
        loggedIn ? const MainScreen() : const GetStartedPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Block UI completely until auth resolves
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
