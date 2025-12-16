import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static int? userpid;
  static String? userphone;
  static String? userpassword;
  static String? useremail;
  static String? userfullname;

  static Future<void> saveSession({
    required int pid,
    required String phonenumber,
    required String password,
    required String email,
    required String fullname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use consistent keys with UserDataManager
    await prefs.setInt('user_pid', pid);
    await prefs.setString('user_phone', phonenumber);
    await prefs.setString('user_password', password);
    await prefs.setString('user_emailaddress', email);
    await prefs.setString('user_fullname', fullname);

    // Update static variables
    userpid = pid;
    userphone = phonenumber;
    userpassword = password;
    useremail = email;
    userfullname = fullname;
  }

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use consistent keys with UserDataManager
    userpid = prefs.getInt('user_pid');
    userphone = prefs.getString('user_phone');
    userpassword = prefs.getString('user_password');
    useremail = prefs.getString('user_emailaddress');
    userfullname = prefs.getString('user_fullname');
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear specific keys instead of all prefs
    await prefs.remove('user_pid');
    await prefs.remove('user_phone');
    await prefs.remove('user_password');
    await prefs.remove('user_emailaddress');
    await prefs.remove('user_fullname');

    // Clear static variables
    userpid = null;
    userphone = null;
    userpassword = null;
    useremail = null;
    userfullname = null;
  }

  static bool isUserLoggedIn() {
    return userpid != null && userpid != 0 && 
           userfullname != null && userfullname!.isNotEmpty &&
           useremail != null && useremail!.isNotEmpty;
  }

  static int? getPidSafe() => userpid;
}