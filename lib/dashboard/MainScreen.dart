import 'package:classicspin/dashboard/LowerGroupScreen.dart';
import 'package:classicspin/dashboard/HomeScreen.dart';
import 'package:classicspin/dashboard/HigherGroupScreen.dart';
import 'package:classicspin/useraccount/ChangePasswordScreen.dart';
import 'package:classicspin/useraccount/LoginPage.dart';
import 'package:classicspin/utils/UserDataManager.dart';
import 'package:classicspin/utils/UserSession.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final int userpid;
  final String phonenumber;
  final String userpassword;
  final String fullname;
  final String emailaddress;

  const MainScreen({
    super.key,
    required this.userpid,
    required this.phonenumber,
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
    // Load user session data from SharedPreferences
    await UserSession.loadSession();
    
    // Determine initial page based on login status
    setState(() {
      if (_isUserLoggedIn()) {
        currentPage = 'Home';
      } else {
        currentPage = 'Login';
      }
      _isLoading = false;
    });
  }

  // Helper method to check if user is logged in
  bool _isUserLoggedIn() {
    // Check UserSession first (loaded from SharedPreferences)
    if (UserSession.isUserLoggedIn()) {
      return true;
    }
    
    // Fallback to widget parameters (for fresh login)
    return widget.userpid != 0 &&
        widget.fullname.isNotEmpty &&
        widget.emailaddress.isNotEmpty;
  }

  // Get current user data (prioritize UserSession)
  Map<String, dynamic> _getCurrentUserData() {
    if (UserSession.isUserLoggedIn()) {
      return {
        'pid': UserSession.userpid ?? 0,
        'phonenumber': UserSession.userphone ?? '',
        'fullname': UserSession.userfullname ?? '',
        'emailaddress': UserSession.useremail ?? '',
        'password': UserSession.userpassword ?? '',
      };
    }
    
    return {
      'pid': widget.userpid,
      'phonenumber': widget.phonenumber,
      'fullname': widget.fullname,
      'emailaddress': widget.emailaddress,
      'password': widget.userpassword,
    };
  }

  // Method to handle successful login
  void handleSuccessfulLogin(
      int pid, String phonenumber, String fullname, String emailaddress, String password) async {
    
    // Save to both UserSession and UserDataManager for consistency
    await UserSession.saveSession(
      pid: pid,
      phonenumber: phonenumber,
      password: password,
      email: emailaddress,
      fullname: fullname,
    );
    
    await UserDataManager.saveUserData(pid, phonenumber, fullname, emailaddress, password);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          userpid: pid,
          phonenumber: phonenumber,
          fullname: fullname,
          emailaddress: emailaddress,
          userpassword: password,
        ),
      ),
    );
  }

  // Method to handle logout
  void handleLogout() async {
    // Clear both UserSession and UserDataManager
    await UserSession.clearSession();
    await UserDataManager.clearUserData();

    // Navigate to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(
          userpid: 0,
          phonenumber: '',
          userpassword: '',
          fullname: '',
          emailaddress: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show login page directly without drawer when user is not logged in
    if (!_isUserLoggedIn() && currentPage == 'Login') {
      return LoginPage(
        onLoginSuccess: handleSuccessfulLogin,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text(
          currentPage,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      // Only show drawer when user is logged in
      drawer: _isUserLoggedIn() ? _buildDrawer() : null,
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    final userData = _getCurrentUserData();
    
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(userData),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: 'Home',
                    isSelected: currentPage == 'Home',
                    onTap: () => _selectPage('Home'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.local_fire_department,
                    title: 'Classic Queue',
                    isSelected: currentPage == 'Classic',
                    onTap: () => _selectPage('Classic'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.star_border,
                    title: 'Premium Queue',
                    isSelected: currentPage == 'Premium',
                    onTap: () => _selectPage('Premium'),
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.lock_open,
                    title: 'Change Password',
                    isSelected: currentPage == 'Password',
                    onTap: () => _selectPage('Password'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.exit_to_app,
                    title: 'Logout',
                    isSelected: currentPage == 'Logout',
                    onTap: () => _selectPage('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(Map<String, dynamic> userData) {
    return UserAccountsDrawerHeader(
      accountName: Text(
        userData['fullname'] ?? '',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      accountEmail: Text(
        userData['emailaddress'] ?? '',
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.asset(
            'assets/images/spinlogo.png',
            fit: BoxFit.cover,
            width: 90,
            height: 90,
          ),
        ),
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF1565C0) : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
      selectedTileColor: const Color(0xFF1565C0).withOpacity(0.1),
    );
  }

  void _selectPage(String page) {
    setState(() {
      currentPage = page;
    });
    Navigator.pop(context);
  }

  Widget _buildBody() {
    final userData = _getCurrentUserData();
    
    switch (currentPage) {
      case 'Home':
        return HomeScreen(
          pid: userData['pid'],
          fullname: userData['fullname'],
          emailaddress: userData['emailaddress'],
        );
      case 'Login':
        return LoginPage(
          onLoginSuccess: handleSuccessfulLogin,
        );
      case 'Classic':
        return LowerGroupScreen(
          pid: userData['pid'],
          fullname: userData['fullname'],
          phonenumber: userData['phonenumber'],
          emailaddress: userData['emailaddress'],
        );
      case 'Premium':
        return HigherGroupScreen(
          pid: userData['pid'],
          fullname: userData['fullname'],
          phonenumber: userData['phonenumber'],
          emailaddress: userData['emailaddress'],
        );
      case 'Password':
        return const ChangePasswordScreen();
      case 'Logout':
        return _buildLogoutScreen();
      default:
        return _isUserLoggedIn()
            ? HomeScreen(
                pid: userData['pid'],
                fullname: userData['fullname'],
                emailaddress: userData['emailaddress'],
              )
            : LoginPage(
                onLoginSuccess: handleSuccessfulLogin,
              );
    }
  }

  Widget _buildLogoutScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, size: 80, color: Color(0xFF1565C0)),
              const SizedBox(height: 20),
              const Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          currentPage = 'Home';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}