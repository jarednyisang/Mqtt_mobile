import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:surveyhub/useraccount/LoginPage.dart';
import 'package:surveyhub/utils/BaseUrl.dart';
import 'package:surveyhub/utils/UserDataManager.dart';


// Add this import

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
    int? pid ;
  String newPassword = '', confirmPassword = '';
  String currentPassword = '';
  bool _loading = false;
     String errorMessage = '';
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  @override
  void initState() {
    super.initState();
    getUserPid();
  }
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
    void getUserPid() async {
  final userData = await UserDataManager.getUserData();
  pid = userData['pid'];
    currentPassword = userData['password'];

}
 Future<void> _changePassword() async {
  setState(() {
    _loading = true;
    errorMessage = '';
  });

  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    _showErrorSnackBar("No network connection. Please check your internet.");
    setState(() => _loading = false);
    return;
  }

  final uri = Uri.parse(BaseUrl.UPDATEPASSWORD);

  try {
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'PID': pid,
        'NEWPASSWORD1': _newPasswordController.text.trim(),
      }),
    ).timeout(const Duration(seconds: 30));

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);

      if (responseBody['error'] == false) {
        _showSuccessSnackBar('Password changed successfully!');

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LoginPage(
                onLoginSuccess: (pid, sid, fullname, email,password) {},
              ),
            ),
            (route) => false,
          );
        }
      } else {
        _showErrorSnackBar(responseBody['message'] ?? 'Failed to change password.');
      }
    } else {
      _showErrorSnackBar('Error ${response.statusCode}. Try again.');
    }
  } on SocketException {
    _showErrorSnackBar('Network connection failed. Check your internet.');
  } on TimeoutException {
    _showErrorSnackBar('Request timeout. Please try again.');
  } on FormatException {
    _showErrorSnackBar('Invalid response format.');
  } catch (e) {
    _showErrorSnackBar('An unexpected error occurred.');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
void _submit() {
  if (_formKey.currentState?.validate() ?? false) {
    final oldPassword = currentPassword.trim();
    final enteredCurrent = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    // 1. Check if current password matches cache
    if (enteredCurrent != oldPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Current password is incorrect"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Check if new = old
    if (newPass == oldPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New password cannot be the same as current password"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 3. Check if new matches confirm
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New passwords do not match"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // ✅ Passed all checks → proceed
    _changePassword();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildChangePasswordContent(),
    );
  }

  Widget _buildChangePasswordContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(   color: Colors.blue, // Changed to blue color
                        strokeWidth: 2.0),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildChangePasswordForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [      
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            "Fill the form to update your password.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 100,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangePasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCurrentPasswordField(),
          const SizedBox(height: 20),
          _buildNewPasswordField(),
          const SizedBox(height: 20),
          _buildConfirmPasswordField(),
          const SizedBox(height: 32),
          _buildChangePasswordButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCurrentPasswordField() {
    return TextFormField(
      controller: _currentPasswordController,
      obscureText: _obscureCurrentPassword,
      decoration: InputDecoration(
        labelText: "Current Password",
        hintText: "Enter your current password",
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.blue,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
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
      validator: (val) => val == null || val.isEmpty ? 'Please enter your current password' : null,
      onSaved: (val) => currentPassword = val ?? '',
    );
  }

  Widget _buildNewPasswordField() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: _obscureNewPassword,
      decoration: InputDecoration(
        labelText: "New Password",
        hintText: "Enter your new password",
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.blue,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
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
      validator: (val) => val != null && val.length >= 4 ? null : 'Password must be at least 4 characters',
      onSaved: (val) => newPassword = val ?? '',
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: "Confirm Password",
        hintText: "Confirm your new password",
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.blue,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
      validator: (val) => val != null && val.length >= 4 ? null : 'Password must be at least 4 characters',
      onSaved: (val) => confirmPassword = val ?? '',
    );
  }

  Widget _buildChangePasswordButton() {
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
        "CHANGE PASSWORD",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
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