import 'package:classicspin/dashboard/MainScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Check if user data exists
    int? pid = prefs.getInt('user_pid');
    String? phonenumber = prefs.getString('user_phone');
    String? fullname = prefs.getString('user_fullname');
    String? emailaddress = prefs.getString('user_email');
    String? password = prefs.getString('user_password');
    
    // Wait for 2 seconds to show splash screen
    await Future.delayed(Duration(seconds: 2));
    
    // Navigate based on login status
    // User is logged in, go to main screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          userpid: pid ?? 0,
          phonenumber: phonenumber ?? '',
          userpassword: password ?? '',
          fullname: fullname ?? '',
          emailaddress: emailaddress ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Gradient from a mix of blue and grey
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900, // A deep, rich blue
              Colors.grey.shade800, // A dark grey for contrast
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular avatar with a border and shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 5,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70, // Increased radius for a more prominent logo
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/spinlogo.png',
                      fit: BoxFit.cover,
                      width: 140, // Match the radius to make it a full circle
                      height: 140,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Queue Cash',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48),
              // Circular progress indicator with brand colors
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                backgroundColor: Colors.green.shade400.withOpacity(0.2),
                strokeWidth: 4.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}