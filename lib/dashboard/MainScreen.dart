import 'package:flutter/material.dart';
import 'package:surveyhub/dashboard/HomeScreen.dart';
import 'package:surveyhub/useraccount/ChangePasswordScreen.dart';
import 'package:surveyhub/useraccount/LoginPage.dart';
import 'package:surveyhub/utils/UserDataManager.dart';
import 'package:surveyhub/utils/UserSession.dart';

class MainScreen extends StatefulWidget {
  final int userpid;
  final String code;
  final String userpassword;
  final String fullname;
  final String emailaddress;

  const MainScreen({
    super.key,
    required this.userpid,
    required this.code,
    required this.fullname,
    required this.emailaddress,
    required this.userpassword,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String currentPage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserSession();
  }

  Future<void> _initializeUserSession() async {
    // Load user session from SharedPreferences
    await UserSession.loadSession();

    setState(() {
      if (_isUserLoggedIn()) {
        currentPage = 'Home';
      } else {
        currentPage = 'Login';
      }
      _isLoading = false;
    });
  }

  // Check if user is logged in
  bool _isUserLoggedIn() {
    if (UserSession.isUserLoggedIn()) return true;

    return widget.userpid != 0 &&
        widget.fullname.isNotEmpty &&
        widget.emailaddress.isNotEmpty;
  }

  // Read user data
  Map<String, dynamic> _getCurrentUserData() {
    if (UserSession.isUserLoggedIn()) {
      return {
        'pid': UserSession.userpid ?? 0,
        'code': UserSession.code ?? '',
        'fullname': UserSession.userfullname ?? '',
        'emailaddress': UserSession.useremail ?? '',
        'password': UserSession.userpassword ?? '',
      };
    }

    return {
      'pid': widget.userpid,
      'code': widget.code,
      'fullname': widget.fullname,
      'emailaddress': widget.emailaddress,
      'password': widget.userpassword,
    };
  }

  // After login success
  void handleSuccessfulLogin(
      int pid, String code, String fullname, String emailaddress, String password) async {
    
    await UserSession.saveSession(
      pid: pid,
      code: code,
      password: password,
      email: emailaddress,
      fullname: fullname,
    );

    await UserDataManager.saveUserData(pid, code, fullname, emailaddress, password);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          userpid: pid,
          code: code,
          fullname: fullname,
          emailaddress: emailaddress,
          userpassword: password,
        ),
      ),
    );
  }

  // Logout
  void handleLogout() async {
    await UserSession.clearSession();
    await UserDataManager.clearUserData();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(
          userpid: 0,
          code: '',
          userpassword: '',
          fullname: '',
          emailaddress: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show login first
    if (!_isUserLoggedIn() && currentPage == 'Login') {
      return LoginPage(
        onLoginSuccess: handleSuccessfulLogin,
      );
    }

    return Scaffold(
      appBar: null, // No AppBar
      body: _buildBody(), // Clean body only
    );
  }

  void _selectPage(String page) {
    setState(() {
      currentPage = page;
    });
  }

  Widget _buildBody() {
    final userData = _getCurrentUserData();

    switch (currentPage) {
      case 'Home':
        return HomeScreen(
          pid: userData['pid'],
          fullname: userData['fullname'],
          code: userData['code'],
          emailaddress: userData['emailaddress'],
        );

      case 'Login':
        return LoginPage(
          onLoginSuccess: handleSuccessfulLogin,
        );

      case 'Password':
        return const ChangePasswordScreen();

      default:
        return _isUserLoggedIn()
            ? HomeScreen(
                pid: userData['pid'],
                fullname: userData['fullname'],
                code: userData['code'],
                emailaddress: userData['emailaddress'],
              )
            : LoginPage(
                onLoginSuccess: handleSuccessfulLogin,
              );
    }
  }
}
