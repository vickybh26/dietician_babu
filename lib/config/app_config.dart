/// Public application configuration. Never put server API secrets here.
class AppSecrets {
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const razorpayKey = String.fromEnvironment('RAZORPAY_KEY');
}
