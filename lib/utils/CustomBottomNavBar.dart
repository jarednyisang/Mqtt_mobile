import 'package:flutter/material.dart';
import 'package:surveyhub/dashboard/HomeScreen.dart';
import 'package:surveyhub/settings/SettingScreen.dart';
import 'package:surveyhub/solar/SolarScreen.dart';


class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String fullname;
  final String code;
  final int userpid;
    final String emailaddress;


  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.fullname,
    required this.code,
    required this.userpid,
        required this.emailaddress,

  });

  void _navigateToScreen(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = HomeScreen(
          pid: userpid,
          fullname: fullname,
          code: code,
           emailaddress: emailaddress,
        );
        break;
      case 1:
        destination = SolarScreen(
          pid: userpid,
          fullname: fullname,
          code: code,
            emailaddress: emailaddress,
        );
        break;
      case 2:
        destination = SolarScreen(
          pid: userpid,
          fullname: fullname,
          code: code,
           emailaddress: emailaddress,
        );
        break;
      case 3:
        destination = SolarScreen(
          pid: userpid,
          fullname: fullname,
          code: code,
            emailaddress: emailaddress,
        );
        break;
      case 4:
        destination = SolarScreen(
          pid: userpid,
          fullname: fullname,
          code: code,
           emailaddress: emailaddress,
        );
        break;
      case 5:
        destination = SettingScreen(
          pid: userpid,
          fullname: fullname,
          code: code,
            emailaddress: emailaddress,
        );
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _navigateToScreen(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: Colors.blue.shade900,
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          items: [
            _buildNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: "Home",
              isActive: currentIndex == 0,
              theme: theme,
            ),
            _buildNavItem(
              icon: Icons.battery_0_bar,
              activeIcon: Icons.battery_0_bar_outlined,
              label: "Batteries",
              isActive: currentIndex == 1,
              theme: theme,
            ),
            _buildNavItem(
              icon: Icons.solar_power,
              activeIcon: Icons.solar_power_outlined,
              label: "Solar",
              isActive: currentIndex == 2,
              theme: theme,
            ),
            _buildNavItem(
              icon: Icons.energy_savings_leaf,
              activeIcon: Icons.energy_savings_leaf_outlined,
              label: "Energy storage",
              isActive: currentIndex == 3,
              theme: theme,
            ),
         
            _buildNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: "Settings",
              isActive: currentIndex == 4,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required ThemeData theme,
  }) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(activeIcon, size: 24),
      ),
      label: label,
    );
  }
}
