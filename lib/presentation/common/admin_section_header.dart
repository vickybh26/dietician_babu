import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A section header with an optional action button on the right.
/// Drop in above any dashboard section to give it a consistent title style.
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const AdminSectionHeader(this.title, {super.key, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          if (action != null) ...[
            const Spacer(),
            action!,
          ],
        ],
      ),
    );
  }
}
