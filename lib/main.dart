import 'package:flutter/material.dart';
import 'package:taxi_app_user/screen/authcheck_page.dart';

import 'package:taxi_app_user/screen/home_page.dart';
import 'package:taxi_app_user/screen/landingscreen.dart';
import 'package:taxi_app_user/screen/loginscreen.dart';
import 'package:taxi_app_user/screen/main_screen.dart';
import 'package:taxi_app_user/screen/profilescreen.dart';
import 'package:taxi_app_user/screen/splash_screen.dart';
import 'package:taxi_app_user/services/notifications_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();   // 🔔 runtime permission happens here
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TraveLink',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LandingScreen()
    );
  }
}
