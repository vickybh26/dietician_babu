import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A colored pill chip showing a client/subscription status.
/// Reusable across Client Management, Members list, etc.
class AdminStatusChip extends StatelessWidget {
  final String status;

  const AdminStatusChip(this.status, {super.key});

  static const _configs = <String, (Color, Color)>{
    'active':   (Color(0xFF388E3C), Color(0xFFE8F5E9)),
    'pending':  (Color(0xFFF57C00), Color(0xFFFFF3E0)),
    'inactive': (Color(0xFF757575), Color(0xFFF5F5F5)),
    'rejected': (Color(0xFFD32F2F), Color(0xFFFFEBEE)),
    'flagged':  (Color(0xFFD32F2F), Color(0xFFFFEBEE)),
  };

  @override
  Widget build(BuildContext context) {
    final label = status.toLowerCase();
    final cfg = _configs[label] ?? (const Color(0xFF757575), const Color(0xFFF5F5F5));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.$2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.$1.withOpacity(0.35), width: 1),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cfg.$1,
        ),
      ),
    );
  }
}
