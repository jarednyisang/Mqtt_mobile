import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:surveyhub/utils/BaseUrl.dart';



class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _otpResetFormKey = GlobalKey<FormState>();
   String errorMessage = '';
  bool _isLoading = false;
  bool _otpSent = false;
  String _emailForReset = ''; // Store the email after it's successfully sent OTP

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }
Future<void> _sendOtp() async {
  if (!(_emailFormKey.currentState?.validate() ?? false)) return;

  setState(() {
    _isLoading = true;
    errorMessage = '';
  });

  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    _showErrorSnackBar("No internet connection.");
    setState(() => _isLoading = false);
    return;
  }

  final email = _emailController.text.trim();
  final url = Uri.parse(BaseUrl.SENDEMAILOTP);

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'TOEMAIL': email}),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        _otpSent = true;
        _emailForReset = email;
      });
      _showSuccessSnackBar(data['message'] ?? 'OTP sent successfully!');
    } else {
      _showErrorSnackBar(data['message'] ?? 'Failed to send OTP.');
    }
  } on SocketException {
    _showErrorSnackBar('Check your internet connection.');
  } on TimeoutException {
    _showErrorSnackBar('Request timed out.');
  } on FormatException {
    _showErrorSnackBar('Invalid response format.');
  } catch (e) {
    _showErrorSnackBar('Something went wrong. Please try again.');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
Future<void> _verifyOtpAndResetPassword() async {
  if (!(_otpResetFormKey.currentState?.validate() ?? false)) return;

  final otp = _otpController.text.trim();
  final newPassword = _newPasswordController.text.trim();
  final confirmPassword = _confirmNewPasswordController.text.trim();

  if (newPassword != confirmPassword) {
    _showErrorSnackBar('Passwords do not match.');
    return;
  }

  setState(() => _isLoading = true);

  final url = Uri.parse(BaseUrl.VERIFYOTPANDRESETPASSWORD);

  try {
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'EMAIL': _emailForReset,
        'OTP': otp,
        'NEWPASSWORD1': newPassword,
      }),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      _showSuccessSnackBar(data['message'] ?? 'Password reset successful.');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _showErrorSnackBar(data['message'] ?? 'Reset failed. Check OTP.');
    }
  } on SocketException {
    _showErrorSnackBar('No internet connection.');
  } on TimeoutException {
    _showErrorSnackBar('Timeout. Please try again.');
  } on FormatException {
    _showErrorSnackBar('Invalid response format.');
  } catch (e) {
    _showErrorSnackBar('Something went wrong. Please try again.');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Forgot Password'),
       backgroundColor: Colors.blue, // or Color(0xFF1A73E8)

        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const CircularProgressIndicator(   color: Colors.blue, // Changed to blue color
                        strokeWidth: 2.0) // Show loader when loading
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _otpSent ? "Enter OTP & New Password" : "Reset Your Password",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _otpSent
                          ? "An OTP has been sent to your email. Enter it below along with your new password."
                          : "Enter your email to receive a password reset OTP.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (!_otpSent) // Show email input initially
                      Form(
                        key: _emailFormKey,
                        child: TextFormField(
                          controller: _emailController,
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
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => val != null && val.contains('@') && val.isNotEmpty
                              ? null
                              : 'Enter a valid email',
                        ),
                      )
                    else // Show OTP and new password fields after OTP is sent
                      Form(
                        key: _otpResetFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: TextEditingController(text: _emailForReset), // Prefill with sent email
                              readOnly: true, // Make it not editable
                              decoration: InputDecoration(
                                labelText: "Email",
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade200, // Slightly different fill color for read-only
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _otpController,
                              decoration: InputDecoration(
                                labelText: "OTP",
                                hintText: "Enter the OTP",
                                prefixIcon: Icon(
                                  Icons.vpn_key_outlined,
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
                              keyboardType: TextInputType.number,
                              validator: (val) =>
                                  val != null && val.length == 5 // Assuming 6-digit OTP
                                      ? null
                                      : 'Enter a valid 5-digit OTP',
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "New Password",
                                hintText: "Enter your new password",
                                prefixIcon: Icon(
                                  Icons.lock_outline,
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
                              validator: (val) => val != null && val.length >= 4
                                  ? null
                                  : 'Password must be at least 4 characters',
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _confirmNewPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "Confirm New Password",
                                hintText: "Re-enter your new password",
                                prefixIcon: Icon(
                                  Icons.lock_reset,
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
                              validator: (val) => val != null && val == _newPasswordController.text
                                  ? null
                                  : 'Passwords do not match',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null // Disable button when loading
                          : (_otpSent ? _verifyOtpAndResetPassword : _sendOtp), // Call appropriate function
                      style: ElevatedButton.styleFrom(
backgroundColor: Colors.blue, // or Color(0xFF1A73E8)
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _isLoading
                            ? 'Processing...'
                            : (_otpSent ? "RESET PASSWORD" : "SEND OTP"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
  void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

void _showSuccessSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

}