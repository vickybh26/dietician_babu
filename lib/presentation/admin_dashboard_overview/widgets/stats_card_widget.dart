import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A stats card with a left-side accent bar, circular icon, and trend badge.
/// The accent bar color matches the metric's iconColor for instant visual grouping.
class StatsCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color changeColor;
  final IconData icon;
  final Color iconColor;

  const StatsCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.changeColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we should show up/down arrows based on color intent
    final isPositive = changeColor == Colors.green ||
        changeColor == const Color(0xFF2E7D32) ||
        changeColor == const Color(0xFF388E3C);
    final isNegative = changeColor == Colors.red ||
        changeColor == const Color(0xFFD32F2F);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // Left accent bar — unique per metric
        border: Border(left: BorderSide(color: iconColor, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(2),
          bottomLeft: Radius.circular(2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: trend badge + circle icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Trend badge with optional arrow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPositive)
                        Icon(Icons.arrow_upward, size: 10, color: changeColor),
                      if (isNegative)
                        Icon(Icons.arrow_downward, size: 10, color: changeColor),
                      if (isPositive || isNegative) const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          change,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Circle icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Value
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
