class BaseUrl {
  static const String BASE_URL = "https://qcash.siliconhighland.com";
   static const String MPESA_BASE_URL = "https://qcash.siliconhighland.com/QcashMpesa";
  static const String LOGIN = "$BASE_URL/api/login";
  static const String SIGNUP = "$BASE_URL/api/register";
  static const String VERIFYOTPANDRESETPASSWORD = "$BASE_URL/api/forgotpassword"; 
  static const String SENDEMAILOTP = "$BASE_URL/api/sendPasswordMessage";
  static const String UPDATEPASSWORD = "$BASE_URL/api/updatepassword";
  static const String GETCOUNTRIES = "$BASE_URL/api/fetchcountries";

    static const String STKPUSH = "$MPESA_BASE_URL/api/stkpush";
    static const String PAYMENTSTATUS = "$MPESA_BASE_URL/api/paymentstatus";
    static const String PAYMENTRESULTS = "$MPESA_BASE_URL/api/stkpush";



}