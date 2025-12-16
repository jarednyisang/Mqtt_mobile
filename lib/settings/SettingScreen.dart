import 'package:flutter/material.dart';
import 'package:surveyhub/utils/AppColors.dart';
import 'package:surveyhub/utils/CustomBottomNavBar.dart';
import 'package:surveyhub/useraccount/LoginPage.dart';
import 'package:surveyhub/utils/UserDataManager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:surveyhub/utils/BaseUrl.dart';
import 'dart:convert';

class SettingScreen extends StatefulWidget {
  final int pid;
  final String fullname;
  final String code;
    final String emailaddress;

  const SettingScreen({
    super.key,
    required this.pid,
    required this.fullname,
    required this.code,
    required this.emailaddress
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildSettingsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        fullname: widget.fullname,
        code: widget.code,
        userpid: widget.pid,
        emailaddress: widget.emailaddress

      ),
    );
  }

  /// HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(
            Icons.settings,
            color: AppColors.white,
            size: 28,
          ),
        ],
      ),
    );
  }

  /// SETTINGS LIST (Change Password & Logout)
  Widget _buildSettingsList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      children: [
        _buildSettingsTile(
          icon: Icons.lock_outline,
          title: "Change Password",
          color: Colors.blue.shade600,
          onTap: () => _showChangePasswordModal(),
        ),
        const SizedBox(height: 20),
        _buildSettingsTile(
          icon: Icons.logout,
          title: "Logout",
          color: Colors.red.shade600,
          onTap: _confirmLogout,
        ),
      ],
    );
  }

  /// Reusable Settings Tile
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.grey700,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// Error State
  Widget _buildErrorState() {
    return Center(
      child: Text(
        _errorMessage ?? 'An error occurred.',
        style: TextStyle(color: AppColors.red600),
      ),
    );
  }

  /// Change Password Modal
  void _showChangePasswordModal() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoadingModal = false;

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    "Change Password",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Current Password",
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? "Enter current password" : null,
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "New Password",
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              val == null || val.length < 4 ? "Min 4 characters" : null,
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Confirm Password",
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Confirm your password";
                            }
                            if (val != newPasswordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),
                        isLoadingModal
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  if (formKey.currentState?.validate() ?? false) {
                                    setModalState(() => isLoadingModal = true);

                                    final connectivityResult =
                                        await Connectivity().checkConnectivity();
                                    if (connectivityResult == ConnectivityResult.none) {
                                      _showSnackBar("No internet connection", Colors.red);
                                      setModalState(() => isLoadingModal = false);
                                      return;
                                    }

                                    final response = await http.put(
                                      Uri.parse(BaseUrl.UPDATEPASSWORD),
                                      headers: {
                                        'Content-Type': 'application/json; charset=UTF-8',
                                      },
                                      body: jsonEncode({
                                        'PID': widget.pid,
                                        'NEWPASSWORD1': newPasswordController.text.trim(),
                                      }),
                                    );

                                    setModalState(() => isLoadingModal = false);

                                    if (response.statusCode == 200) {
                                      final data = jsonDecode(response.body);
                                      if (data['error'] == false) {
                                        _showSnackBar("Password changed successfully!", Colors.green);
                                        Navigator.pop(context);

                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LoginPage(
                                              onLoginSuccess: (pid, sid, fullname, email, password) {},
                                            ),
                                          ),
                                          (route) => false,
                                        );
                                      } else {
                                        _showSnackBar(data['message'] ?? "Failed to change password", Colors.red);
                                      }
                                    } else {
                                      _showSnackBar("Server error ${response.statusCode}", Colors.red);
                                    }
                                  }
                                },
                                child: const Text(
                                  "UPDATE PASSWORD",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Logout confirmation
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await UserDataManager.clearUserData();

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(
                      onLoginSuccess: (pid, sid, fullname, email, password) {},
                    ),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
