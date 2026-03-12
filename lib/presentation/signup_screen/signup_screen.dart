import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firebase_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Create Firebase Auth account
      final cred = await FirebaseService.instance.registerWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );

      // Set display name so upsertUser picks it up correctly
      await cred.user!.updateDisplayName(_nameCtrl.text.trim());

      // ✅ FIX: Reload the user to pick up the updated displayName before
      // saving to Firestore. Without this, upsertUser sees the stale user
      // object where displayName is still null, causing the name to not save.
      await cred.user!.reload();
      final refreshedUser = FirebaseService.instance.auth.currentUser!;

      // Sync to Firestore via the canonical upsertUser helper.
      // Also write phone (not covered by upsertUser) and mark onboarding pending.
      await FirebaseService.instance.upsertUser(refreshedUser);
      await FirebaseService.instance.users.doc(refreshedUser.uid).update({
        'phone': _phoneCtrl.text.trim(),
        'onboardingComplete': false,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(
            context, '/health-profile-onboarding');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Sign up failed. Please try again.';
        switch (e.code) {
          case 'email-already-in-use':
            msg = 'An account with this email already exists. Sign in instead.';
            break;
          case 'weak-password':
            msg = 'Password must be at least 6 characters.';
            break;
          case 'invalid-email':
            msg = 'Please enter a valid email address.';
            break;
          case 'network-request-failed':
            msg = 'No internet connection. Check your network and try again.';
            break;
        }
        _showError(msg);
      }
    } catch (e) {
      if (mounted) _showError('Sign up failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Account',
          style: GoogleFonts.inter(
            color: Colors.grey[800],
            fontWeight: FontWeight.w700,
            fontSize: 13.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 4.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Join Dietician Babu 🥗',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.sp,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Start your health journey today. Takes less than a minute.',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),

              SizedBox(height: 3.5.h),

              // Full Name
              _label('Full Name *'),
              _buildField(
                controller: _nameCtrl,
                hint: 'e.g. Rahul Sharma',
                icon: Icons.person_outline_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please enter your name';
                  if (v.trim().length < 2)
                    return 'Name must be at least 2 characters';
                  return null;
                },
              ),

              SizedBox(height: 2.h),

              // Email
              _label('Email Address *'),
              _buildField(
                controller: _emailCtrl,
                hint: 'e.g. rahul@gmail.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please enter your email';
                  if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$')
                      .hasMatch(v.trim()))
                    return 'Please enter a valid email address';
                  return null;
                },
              ),

              SizedBox(height: 2.h),

              // Phone (optional)
              _label('Phone Number (optional)'),
              _buildField(
                controller: _phoneCtrl,
                hint: 'e.g. 9876543210',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              SizedBox(height: 2.h),

              // Password
              _label('Password *'),
              _buildField(
                controller: _passCtrl,
                hint: 'Minimum 6 characters',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Please enter a password';
                  if (v.length < 6)
                    return 'Password must be at least 6 characters';
                  return null;
                },
              ),

              SizedBox(height: 2.h),

              // Confirm Password
              _label('Confirm Password *'),
              _buildField(
                controller: _confirmPassCtrl,
                hint: 'Re-enter your password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Please confirm your password';
                  if (v != _passCtrl.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),

              SizedBox(height: 4.h),

              // Create Account button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF1976D2).withOpacity(0.5),
                    padding: EdgeInsets.symmetric(vertical: 1.9.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Create Account  →',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp),
                        ),
                ),
              ),

              SizedBox(height: 2.h),

              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.inter(
                        fontSize: 10.5.sp, color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                        context, '/login-screen'),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.5.h),

              // Terms note
              Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                style: GoogleFonts.inter(
                  fontSize: 8.sp,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.7.h),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 11.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: Colors.grey[400], fontSize: 11.sp),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.7.h),
      ),
    );
  }
}
