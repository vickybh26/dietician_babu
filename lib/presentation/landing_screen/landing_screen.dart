import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // ── Update these with Dietician Babu's actual contact details ────────────
  static const String _whatsappNumber = '918871448064'; // without +
  static const String _callNumber = '+918871448064';

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
        'https://wa.me/$_whatsappNumber?text=Hi%20Dietician%20Babu%2C%20I%20want%20to%20know%20more%20about%20your%20diet%20plans.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _callUs(BuildContext context) async {
    final uri = Uri.parse('tel:$_callNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(context),
              _buildAboutSection(),
              _buildBenefitsSection(),
              _buildPlansTeaser(context),
              _buildContactSection(context),
              _buildFooter(context),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF1976D2), Color(0xFF43A047)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 5.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar: logo + sign in
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/Logo_DB-removebg-preview-1757171544580.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Dietician Babu',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/login-screen'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.inter(
                        fontSize: 10.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            SizedBox(height: 4.h),

            // Tagline
            Text(
              'Your Personal\nDietician,\nRight in Your Pocket 🥗',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17.sp,
                height: 1.25,
              ),
            ),

            SizedBox(height: 1.5.h),

            Text(
              'Science-backed personalised diet plans tailored to your goals, '
              'lifestyle, and health conditions.',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10.5.sp,
                height: 1.55,
              ),
            ),

            SizedBox(height: 3.5.h),

            // CTA row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1976D2),
                      padding: EdgeInsets.symmetric(vertical: 1.7.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Get Started 🚀',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 11.sp),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                OutlinedButton(
                  onPressed: () => _openWhatsApp(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: EdgeInsets.symmetric(
                        vertical: 1.7.h, horizontal: 4.w),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 15)),
                      SizedBox(width: 1.w),
                      Text(
                        'Chat',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  // ── About ────────────────────────────────────────────────────────────────
  Widget _buildAboutSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who We Are',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 14.sp,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.2.h),
          Text(
            'Dietician Babu is an Indore-based nutrition consultancy run by a '
            'certified dietician with over 7 years of experience. We specialise '
            'in weight management, therapeutic diets, and lifestyle transformation '
            '— all from the comfort of your home.',
            style: GoogleFonts.inter(
              fontSize: 10.5.sp,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
          SizedBox(height: 2.5.h),
          Row(
            children: [
              _statBubble('500+', 'Clients\nHelped', const Color(0xFF1976D2)),
              SizedBox(width: 2.w),
              _statBubble('7+', 'Years\nExp.', const Color(0xFF43A047)),
              SizedBox(width: 2.w),
              _statBubble('98%', 'Satisfaction', const Color(0xFFf5a40d)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBubble(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 13.sp,
                color: color,
              ),
            ),
            SizedBox(height: 0.4.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                color: Colors.grey[600],
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Benefits ─────────────────────────────────────────────────────────────
  Widget _buildBenefitsSection() {
    final benefits = [
      {
        'icon': '🎯',
        'title': 'Personalised Plans',
        'desc':
            'Diet plans created specifically for your body, goals, and food preferences.',
      },
      {
        'icon': '📱',
        'title': 'Track Progress',
        'desc':
            'Log meals, water intake, and weight. Watch your transformation week by week.',
      },
      {
        'icon': '💬',
        'title': 'Direct Support',
        'desc':
            'WhatsApp support directly with your dietician. No middlemen, no delays.',
      },
      {
        'icon': '🔄',
        'title': 'Weekly Check-ins',
        'desc':
            'Regular reviews and plan adjustments to keep you on track toward your goal.',
      },
    ];

    return Container(
      color: Colors.grey[50],
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose Us',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 14.sp,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          ...benefits.map((b) => _benefitRow(b)),
        ],
      ),
    );
  }

  Widget _benefitRow(Map<String, String> b) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 11.w,
            height: 11.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(b['icon']!, style: const TextStyle(fontSize: 20)),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b['title']!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  b['desc']!,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Plans teaser ─────────────────────────────────────────────────────────
  Widget _buildPlansTeaser(BuildContext context) {
    final plans = [
      {
        'name': 'Regular',
        'price': '₹2,499',
        'duration': '30 days',
        'color': const Color(0xFF61b239),
        'emoji': '🥗',
      },
      {
        'name': 'Rapid',
        'price': '₹4,499',
        'duration': '60 days',
        'color': const Color(0xFFf5a40d),
        'emoji': '⚡',
        'popular': true,
      },
      {
        'name': 'Super',
        'price': '₹5,999',
        'duration': '90 days',
        'color': const Color(0xFF9c27b0),
        'emoji': '🏆',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Plans',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 14.sp,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 0.4.h),
          Text(
            'Choose a plan that fits your journey',
            style: GoogleFonts.inter(
                fontSize: 10.sp, color: Colors.grey[500]),
          ),
          SizedBox(height: 2.h),
          Row(
            children: plans.map((plan) {
              final color = plan['color'] as Color;
              final isPopular = plan['popular'] == true;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isPopular ? color : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isPopular ? color : color.withOpacity(0.3),
                      width: isPopular ? 0 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            color.withOpacity(isPopular ? 0.3 : 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          margin: EdgeInsets.only(bottom: 0.8.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'TOP',
                            style: GoogleFonts.inter(
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      Text(plan['emoji'] as String,
                          style: const TextStyle(fontSize: 20)),
                      SizedBox(height: 0.5.h),
                      Text(
                        plan['name'] as String,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5.sp,
                          color: isPopular
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 0.4.h),
                      Text(
                        plan['price'] as String,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 11.sp,
                          color: isPopular ? Colors.white : color,
                        ),
                      ),
                      Text(
                        plan['duration'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 7.5.sp,
                          color: isPopular
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/signup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.7.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Subscribe Now 🚀',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 12.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact ───────────────────────────────────────────────────────────────
  Widget _buildContactSection(BuildContext context) {
    return Container(
      color: const Color(0xFF1E3A8A),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have Questions?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 14.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Reach out to us directly before signing up.',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 2.5.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.7.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Text('💬',
                      style: TextStyle(fontSize: 15)),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 11.sp),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callUs(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: EdgeInsets.symmetric(vertical: 1.7.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 17),
                  label: Text(
                    'Call Now',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 11.sp),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
      child: Column(
        children: [
          const Divider(),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: Colors.grey[600]),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/login-screen'),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Text(
            '© 2025 Dietician Babu · Indore, Madhya Pradesh',
            style: GoogleFonts.inter(
                fontSize: 8.sp, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
