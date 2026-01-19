import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:taxi_app_user/screen/landingscreen.dart';
import 'package:taxi_app_user/screen/splash_screen.dart';
import 'package:taxi_app_user/services/notifications_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ System UI setup (no black bars, navbar visible)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,

      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TraveLink',

      // 🔥 FORCE LIGHT MODE (OPTION A)
      themeMode: ThemeMode.light,

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),

        // Ensures text is ALWAYS dark
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black),
        ),
      ),

      home: const LandingScreen()
    );
  }
}
