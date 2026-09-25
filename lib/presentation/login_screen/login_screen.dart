import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import './widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Email/password
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  // Phone OTP
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  String _verificationId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error
          ? AppTheme.lightTheme.colorScheme.error
          : AppTheme.lightTheme.colorScheme.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _afterLogin(UserCredential cred) async {
    await FirebaseService.instance.upsertUser(cred.user!);
    final profile = await FirebaseService.instance.getUserProfile(cred.user!.uid);
    if (!mounted) return;
    if (kIsWeb) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return;
    }
    if (profile?['onboardingComplete'] == true) {
      Navigator.pushReplacementNamed(context, '/dashboard-home');
    } else {
      Navigator.pushReplacementNamed(context, '/health-profile-onboarding');
    }
  }

  // ─── Email Login ────────────────────────────────────────────────────────────
  Future<void> _handleEmailLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showSnack('Please enter email and password', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseService.instance.signInWithEmail(email, pass);
      await _afterLogin(cred);
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'user-not-found'
          ? 'No account found with this email'
          : e.code == 'wrong-password' || e.code == 'invalid-credential'
              ? 'Incorrect password'
              : e.code == 'too-many-requests'
                  ? 'Too many attempts. Try again later.'
                  : 'Login failed. Please try again.';
      _showSnack(msg, error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('Enter your email first', error: true);
      return;
    }
    try {
      await FirebaseService.instance.sendPasswordReset(email);
      _showSnack('Password reset email sent!');
    } catch (_) {
      _showSnack('Could not send reset email', error: true);
    }
  }

  // ─── Phone OTP ─────────────────────────────────────────────────────────────
  Future<void> _handleSendOTP() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      _showSnack('Enter a valid 10-digit mobile number', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseService.instance.sendPhoneOTP(
        phone: phone,
        onAutoVerified: (credential) async {
          final cred = await FirebaseService.instance.auth
              .signInWithCredential(credential);
          await _afterLogin(cred);
        },
        onFailed: (e) {
          _showSnack('Failed to send OTP: ${e.message}', error: true);
          setState(() => _isLoading = false);
        },
        onCodeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          _showSnack('OTP sent to +91 $phone');
        },
      );
    } catch (e) {
      _showSnack('Error: $e', error: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOTP() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 6) {
      _showSnack('Enter the 6-digit OTP', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseService.instance
          .verifyOTP(verificationId: _verificationId, otp: otp);
      await _afterLogin(cred);
    } on FirebaseAuthException {
      _showSnack('Invalid OTP. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseService.instance.signInWithGoogle();
      await _afterLogin(cred);
    } catch (e) {
      final msg = e.toString().contains('cancelled')
          ? 'Sign-in cancelled'
          : 'Google sign-in failed. Please try again.';
      _showSnack(msg, error: !e.toString().contains('cancelled'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            child: Column(
              children: [
                SizedBox(height: 4.h),
                const AppLogo(),
                SizedBox(height: 3.h),

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: '📱 Phone (OTP)'),
                      Tab(text: '✉️ Email'),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),

                SizedBox(
                  height: 42.h,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPhoneTab(),
                      _buildEmailTab(),
                    ],
                  ),
                ),

                SizedBox(height: 2.h),

                // ─── Google Sign-In divider ─────────────────────────────
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Text('or', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ]),
                SizedBox(height: 2.h),

                // ─── Google button ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      padding: EdgeInsets.symmetric(vertical: 1.4.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _GoogleIcon(),
                        SizedBox(width: 3.w),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Color(0xFF3C4043),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New client? ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                          context, '/signup'),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Phone Tab ────────────────────────────────────────────────────────────
  Widget _buildPhoneTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_otpSent) ...[
          _label('Mobile Number'),
          SizedBox(height: 0.8.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('+91',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              SizedBox(width: 2.w),
              Expanded(child: _textField(_phoneCtrl, '9876543210',
                  keyboardType: TextInputType.phone,
                  maxLength: 10)),
            ],
          ),
          SizedBox(height: 2.h),
          _primaryButton('Send OTP', _isLoading ? null : _handleSendOTP),
        ] else ...[
          _label('Enter 6-digit OTP sent to +91 ${_phoneCtrl.text}'),
          SizedBox(height: 1.5.h),
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(10),
              fieldHeight: 52,
              fieldWidth: 42,
              activeFillColor: Colors.white,
              inactiveFillColor: Colors.grey.shade50,
              selectedFillColor: Colors.white,
              activeColor: AppTheme.lightTheme.colorScheme.primary,
              inactiveColor: Colors.grey.shade300,
              selectedColor: AppTheme.lightTheme.colorScheme.primary,
            ),
            enableActiveFill: true,
            onChanged: (_) {},
            onCompleted: (_) => _handleVerifyOTP(),
          ),
          SizedBox(height: 1.5.h),
          _primaryButton('Verify & Login', _isLoading ? null : _handleVerifyOTP),
          SizedBox(height: 1.h),
          TextButton(
            onPressed: () => setState(() {
              _otpSent = false;
              _otpCtrl.clear();
            }),
            child: Text('Change number',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 1.5.h),
              child: CircularProgressIndicator(
                  color: AppTheme.lightTheme.colorScheme.primary),
            ),
          ),
      ],
    );
  }

  // ─── Email Tab ────────────────────────────────────────────────────────────
  Widget _buildEmailTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Email Address'),
        SizedBox(height: 0.8.h),
        _textField(_emailCtrl, 'you@example.com',
            keyboardType: TextInputType.emailAddress),
        SizedBox(height: 1.5.h),
        _label('Password'),
        SizedBox(height: 0.8.h),
        _passwordField(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _handleForgotPassword,
            child: Text('Forgot password?',
                style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontSize: 13)),
          ),
        ),
        _primaryButton('Login', _isLoading ? null : _handleEmailLogin),
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 1.5.h),
              child: CircularProgressIndicator(
                  color: AppTheme.lightTheme.colorScheme.primary),
            ),
          ),
      ],
    );
  }

  // ─── Reusable widgets ─────────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLength: maxLength,
        buildCounter: maxLength != null ? (_, {required currentLength, required isFocused, maxLength}) => null : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary, width: 2),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        ),
      );

  Widget _passwordField() => TextField(
        controller: _passCtrl,
        obscureText: !_showPass,
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary, width: 2),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          suffixIcon: IconButton(
            icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade500),
            onPressed: () => setState(() => _showPass = !_showPass),
          ),
        ),
      );

  Widget _primaryButton(String label, VoidCallback? onPressed) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 1.6.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );
}

// ─── Google coloured "G" icon ────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // Simple coloured G using RichText — no external assets needed
    return RichText(
      text: const TextSpan(
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'sans-serif'),
        children: [
          TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
          TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
          TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
          TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
        ],
      ),
    );
  }
}
