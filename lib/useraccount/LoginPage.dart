import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:classicspin/dashboard/MainScreen.dart';
import 'package:classicspin/useraccount/ForgotPasswordPage.dart';
import 'package:classicspin/useraccount/SignupPage.dart';
import 'package:classicspin/utils/BaseUrl.dart';
import 'package:classicspin/utils/UserSession.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  final void Function(int pid, String phonenumber, String fullname, String emailaddress,String password) onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String _email = '', _password = '';
  bool _loading = false;
  String errorMessage = '';


Future<void> _login() async {
  setState(() {
    _loading = true;
    errorMessage = '';
  });

  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    setState(() {
      errorMessage = "No network connection. Please check your internet connection.";
      _loading = false;
    });

    _showSnackBar(errorMessage, isError: true);
    return;
  }

  try {
    final url = Uri.parse(BaseUrl.LOGIN);
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'Username': _email,
            'Password': _password,
          }),
        )
        .timeout(const Duration(seconds: 30));

    setState(() => _loading = false);

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['error'] == false) {
      final pid = data['pid'];
      final phonenumber = data['phone'];
      final fullname = data['fullname'];
      final emailaddress = data['email'];
      final password = data['password'];

      await UserSession.saveSession(
        pid: pid,
         phonenumber: phonenumber,
        password: password,
        email: emailaddress,
        fullname: fullname,
      );

      widget.onLoginSuccess(pid, phonenumber, fullname, emailaddress,password);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            userpid: pid,
            phonenumber: phonenumber,
            fullname: fullname,
            emailaddress: emailaddress,
            userpassword:password
          ),
        ),
      );
    } else {
      _showSnackBar(data['message'] ?? "Login failed", isError: true);
    }
  } on SocketException {
    setState(() => _loading = false);
    _showSnackBar("No internet connection. Please try again.", isError: true);
  } on TimeoutException {
    setState(() => _loading = false);
    _showSnackBar("Login timed out. Please check your connection and try again.", isError: true);
  } on FormatException {
    setState(() => _loading = false);
    _showSnackBar("Invalid response from server.", isError: true);
  } catch (e) {
    setState(() => _loading = false);
    _showSnackBar("Unexpected error occurred. Please try again.", isError: true);
  }
}

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildLoginContent(),
    );
  }

  Widget _buildLoginContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(  color: Colors.blue, // Changed to blue color
                        strokeWidth: 2.0),
      );
    }

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 59,
            backgroundImage: AssetImage('assets/images/classicpos1.png'),
            backgroundColor: Colors.transparent,
          ),
        ),
        SizedBox(height: 24),
        Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Login to join others in the Queue",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildForgotPassword(),
          const SizedBox(height: 30),
          _buildLoginButton(),
          const SizedBox(height: 24),
          _buildSignUpOption(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Email",
        hintText: "Enter your email",
        prefixIcon: Icon(
          Icons.email_outlined,
          color: Colors.blue,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontSize: 16),
      keyboardType: TextInputType.emailAddress,
      onSaved: (val) => _email = val ?? '',
      onChanged: (_) {
        if (errorMessage.isNotEmpty) {
          setState(() => errorMessage = '');
        }
      },
      validator: (val) => val != null && val.contains('@') ? null : 'Enter a valid email',
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: "Password",
        hintText: "Enter your password",
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.blue,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontSize: 16),
      onSaved: (val) => _password = val ?? '',
      onChanged: (_) {
        if (errorMessage.isNotEmpty) {
          setState(() => errorMessage = '');
        }
      },
      validator: (val) => val != null && val.length >= 4 ? null : 'Password too short',
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
          );
        },
        child: Text(
          "Forgot Password?",
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: const Text(
        "LOGIN",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSignUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: Colors.black54),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage()));
          },
          child: Text(
            "Sign Up",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    ),
  );
}

}
