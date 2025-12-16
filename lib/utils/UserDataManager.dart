import 'package:shared_preferences/shared_preferences.dart';

class UserDataManager {
  static Future<void> saveUserData(int pid, String code
, String fullname, String emailaddress, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_pid', pid);
    await prefs.setString('code', code
);
    await prefs.setString('user_fullname', fullname);
    await prefs.setString('user_emailaddress', emailaddress);
    await prefs.setString('user_password', password);
  }

  static Future<Map<String, dynamic>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'pid': prefs.getInt('user_pid') ?? 0,
      'code': prefs.getString('code') ?? '', // Fixed: was getting int
      'fullname': prefs.getString('user_fullname') ?? '',
      'emailaddress': prefs.getString('user_emailaddress') ?? '',
      'password': prefs.getString('user_password') ?? '', // Fixed: was getting int
    };
  }

  static Future<void> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_pid');
    await prefs.remove('code'); // Fixed: was removing 'user_sid'
    await prefs.remove('user_fullname');
    await prefs.remove('user_emailaddress');
    await prefs.remove('user_password');
  }

  static Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? pid = prefs.getInt('user_pid');
    String fullname = prefs.getString('user_fullname') ?? '';
    String emailaddress = prefs.getString('user_emailaddress') ?? '';
    
    return pid != 0 && fullname.isNotEmpty && emailaddress.isNotEmpty;
  }
}