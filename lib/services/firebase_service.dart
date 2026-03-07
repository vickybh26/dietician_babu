import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../config/secrets.dart';

// ─── Firebase Config ───────────────────────────────────────────────────────────
// ⚠️  Replace with your actual Firebase project values.
// Find them in: Firebase Console → Project Settings → Your Apps → Web App → Config
//
// HOW TO ADD google-services.json (Android):
//   1. Firebase Console → Project Settings → Your Apps → Add Android App
//   2. Download google-services.json
//   3. Place it at: android/app/google-services.json
//
// HOW TO ADD GoogleService-Info.plist (iOS):
//   1. Firebase Console → Project Settings → Your Apps → Add iOS App
//   2. Download GoogleService-Info.plist
//   3. Place it at: ios/Runner/GoogleService-Info.plist

const String _adminEmail = 'dieticianbabu@gmail.com';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get db => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: AppSecrets.firebaseApiKey,
        authDomain: 'dietician-babu-31ka2.firebaseapp.com',
        projectId: 'dietician-babu-31ka2',
        storageBucket: 'dietician-babu-31ka2.firebasestorage.app',
        messagingSenderId: '793278867167',
        appId: '1:793278867167:web:a2f5f6808ea2e8b7392b6a',
      ),
    );
  }

  bool get isAdmin =>
      auth.currentUser?.email == _adminEmail;

  User? get currentUser => auth.currentUser;

  // ─── Auth ─────────────────────────────────────────────────────────────────

  /// Email + password sign in
  Future<UserCredential> signInWithEmail(String email, String password) =>
      auth.signInWithEmailAndPassword(email: email, password: password);

  /// Email + password register
  Future<UserCredential> registerWithEmail(String email, String password) =>
      auth.createUserWithEmailAndPassword(email: email, password: password);

  /// Send phone OTP — pass a 10-digit Indian number, e.g. "9876543210"
  Future<void> sendPhoneOTP({
    required String phone,
    required void Function(PhoneAuthCredential) onAutoVerified,
    required void Function(FirebaseAuthException) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
  }) async {
    final formatted = phone.startsWith('+') ? phone : '+91$phone';
    await auth.verifyPhoneNumber(
      phoneNumber: formatted,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  /// Verify OTP after sendPhoneOTP
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordReset(String email) =>
      auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() => auth.signOut();

  // ─── Firestore helpers ────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get users =>
      db.collection('users');
  CollectionReference<Map<String, dynamic>> get clients =>
      db.collection('clients');
  CollectionReference<Map<String, dynamic>> get plans =>
      db.collection('plans');
  CollectionReference<Map<String, dynamic>> get weeklyUpdates =>
      db.collection('weeklyUpdates');
  CollectionReference<Map<String, dynamic>> get followUps =>
      db.collection('followUps');
  CollectionReference<Map<String, dynamic>> get payments =>
      db.collection('payments');
  CollectionReference<Map<String, dynamic>> get messages =>
      db.collection('messages');

  /// Create or merge user doc after login
  Future<void> upsertUser(User user, {bool onboardingComplete = false}) async {
    final ref = db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'role': user.email == _adminEmail ? 'admin' : 'client',
        'onboardingComplete': onboardingComplete,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Fetch user profile map
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await db.collection('users').doc(uid).get();
    return snap.exists ? snap.data() : null;
  }
}
