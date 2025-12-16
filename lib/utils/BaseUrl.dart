class BaseUrl {
  static const String BASE_URL = "https://chloride.siliconhighland.com";
  static const String LOGIN = "$BASE_URL/api/login";
  static const String SIGNUP = "$BASE_URL/api/register";
  static const String VERIFYOTPANDRESETPASSWORD = "$BASE_URL/api/forgotpassword"; 
  static const String SENDEMAILOTP = "$BASE_URL/api/sendPasswordMessage";
  static const String UPDATEPASSWORD = "$BASE_URL/api/updatepassword";
  static const String GETCOUNTRIES = "$BASE_URL/api/fetchcountries";
    static const String GETDONATIONAMOUNT = "$BASE_URL/api/fetchprice";

  static const String AVAILABLESURVEYS = "$BASE_URL/api/availablesurveys";
  static const String COMPLETEDSURVEYS = "$BASE_URL/api/completedsurveys";
   static const String DASHBOARD = "$BASE_URL/api/dashboard";
  static const String TRANSACTION = "$BASE_URL/api/transactions";
  static const String REFFERALS = "$BASE_URL/api/referrals";
  static const String WITHDRAW = "$BASE_URL/api/withdraw";
  static const String POSTRESPONSE = "$BASE_URL/api/createfeedback";
 // Add these to your BaseUrl class:
  static const String UPDATE_USER_DONATION = '$BASE_URL/api/revenuecat/updateSubscription';
  static const String USER_DONATION_HISTORY = '$BASE_URL/api/revenuecat/subscriptionHistory';
  static const String GET_USER_BY_ID = '$BASE_URL/api/revenuecat/getUserById';
  static const String ACTIVATE_MANUALLY = '$BASE_URL/api/revenuecat/activateManually';
  



static const String PESAPALSUBMITORDER = '$BASE_URL/api/pesapal/submit-order';
static const String PESAPALCALLBACK = '$BASE_URL/api//pesapal/callback';
static const String PESAPALIPN = '$BASE_URL/api/pesapal/ipn';
static const String PESAPALCHECKSTATUS = '$BASE_URL/api/pesapal/check-status';


}