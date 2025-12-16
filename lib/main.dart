
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surveyhub/utils/SplashScreen.dart';
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chloride MQTT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1565C0),
        hintColor: Color(0xFF42A5F5),
        scaffoldBackgroundColor: Color(0xFF2D2D3A),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
            scaffoldMessengerKey: scaffoldMessengerKey,

      home: SplashScreen(), // Start with splash screen to check login status
      debugShowCheckedModeBanner: false,
    );
  }
}





