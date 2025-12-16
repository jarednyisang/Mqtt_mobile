import 'package:flutter/material.dart';
import 'package:surveyhub/utils/AppColors.dart';
import 'package:surveyhub/utils/CustomBottomNavBar.dart';

class SolarScreen extends StatefulWidget {
  final int pid;
  final String fullname;
  final String code;
  final String emailaddress;

  const SolarScreen({
    super.key,
    required this.pid,
    required this.fullname,
    required this.code,
    required this.emailaddress,
  });

  @override
  State<SolarScreen> createState() => _SolarScreenState();
}

class _SolarScreenState extends State<SolarScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        fullname: widget.fullname,
        code: widget.code,
        userpid: widget.pid,
        emailaddress: widget.emailaddress,
      ),
    );
  }

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
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny, color: AppColors.white, size: 40),
          const SizedBox(width: 16),
          Text(
            'Solar Energy',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chloride Exide Solar Solutions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Explore our range of solar energy products and solutions.',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}