import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../services/firebase_service.dart';

/// Client-facing appointments screen.
/// Shows upcoming and past appointments fetched from the top-level
/// `appointments` collection (clientId field links to client).
class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  // ── Type helpers ────────────────────────────────────────────────────────────

  static Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'consultation': return const Color(0xFF1976D2);
      case 'follow-up':   return Colors.teal;
      case 'assessment':  return Colors.orange;
      case 'review':      return Colors.purple;
      default:            return Colors.grey;
    }
  }

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'consultation': return Icons.medical_services_outlined;
      case 'follow-up':   return Icons.repeat_outlined;
      case 'assessment':  return Icons.assignment_outlined;
      case 'review':      return Icons.fact_check_outlined;
      default:            return Icons.calendar_today_outlined;
    }
  }

  static Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'scheduled': return const Color(0xFF1976D2);
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'no-show':   return Colors.orange;
      default:          return Colors.grey;
    }
  }

  static String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'scheduled': return 'Scheduled';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'no-show':   return 'No-show';
      default:          return s;
    }
  }

  // ── Date parsing ────────────────────────────────────────────────────────────

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    return null;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Appointments',
          style: GoogleFonts.inter(
            color: Colors.grey[900],
            fontWeight: FontWeight.w700,
            fontSize: 13.sp,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService.instance.appointments
            .where('clientId', isEqualTo: uid)
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading appointments',
                  style: GoogleFonts.inter(color: Colors.red)),
            );
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final docs = snapshot.data?.docs ?? [];

          final upcoming = docs.where((d) {
            final date = _parseDate(d.data()['date']);
            final status = (d.data()['status'] ?? 'scheduled').toString().toLowerCase();
            if (date == null) return false;
            final apptDay = DateTime(date.year, date.month, date.day);
            return !apptDay.isBefore(today) && status != 'cancelled';
          }).toList();

          final past = docs.where((d) {
            final date = _parseDate(d.data()['date']);
            final status = (d.data()['status'] ?? 'scheduled').toString().toLowerCase();
            if (date == null) return false;
            final apptDay = DateTime(date.year, date.month, date.day);
            return apptDay.isBefore(today) || status == 'cancelled';
          }).toList()
            ..sort((a, b) {
              final da = _parseDate(a.data()['date']);
              final db = _parseDate(b.data()['date']);
              if (da == null || db == null) return 0;
              return db.compareTo(da); // most recent first
            });

          if (docs.isEmpty) {
            return _buildEmpty();
          }

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionHeader('Upcoming', Icons.upcoming_outlined, Colors.green),
                SizedBox(height: 1.h),
                ...upcoming.map((d) => _AppointmentCard(
                      appt: {...d.data(), 'id': d.id},
                      typeColor: _typeColor,
                      typeIcon: _typeIcon,
                      statusColor: _statusColor,
                      statusLabel: _statusLabel,
                      parseDate: _parseDate,
                    )),
                SizedBox(height: 2.h),
              ],
              if (past.isNotEmpty) ...[
                _sectionHeader('Past', Icons.history_outlined, Colors.grey),
                SizedBox(height: 1.h),
                ...past.map((d) => _AppointmentCard(
                      appt: {...d.data(), 'id': d.id},
                      typeColor: _typeColor,
                      typeIcon: _typeIcon,
                      statusColor: _statusColor,
                      statusLabel: _statusLabel,
                      parseDate: _parseDate,
                      isPast: true,
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No appointments yet',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Your dietician will schedule consultations\nand they will appear here.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Appointment Card ─────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final Color Function(String) typeColor;
  final IconData Function(String) typeIcon;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final DateTime? Function(dynamic) parseDate;
  final bool isPast;

  const _AppointmentCard({
    required this.appt,
    required this.typeColor,
    required this.typeIcon,
    required this.statusColor,
    required this.statusLabel,
    required this.parseDate,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final type = appt['type'] as String? ?? 'Consultation';
    final status = appt['status'] as String? ?? 'scheduled';
    final notes = appt['notes'] as String? ?? '';
    final time = appt['time'] as String? ?? '';
    final date = parseDate(appt['date']);

    final color = typeColor(type);
    final icon = typeIcon(type);
    final sColor = statusColor(status);
    final sLabel = statusLabel(status);

    String dateDisplay = '—';
    if (date != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final apptDay = DateTime(date.year, date.month, date.day);
      final diff = apptDay.difference(today).inDays;
      if (!isPast && diff == 0) {
        dateDisplay = 'Today';
      } else if (!isPast && diff == 1) {
        dateDisplay = 'Tomorrow';
      } else {
        dateDisplay = DateFormat('dd MMM yyyy').format(date);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isPast ? Colors.white.withOpacity(0.85) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Stack(
        children: [
          // Color accent on left
          Positioned(
            top: 0, bottom: 0, left: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: isPast ? color.withOpacity(0.35) : color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isPast ? 0.07 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: isPast ? color.withOpacity(0.5) : color),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              type,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isPast ? Colors.grey[500] : Colors.grey[900],
                              ),
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: sColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: sColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            dateDisplay,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isPast ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                          if (time.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_outlined,
                                size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isPast ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          notes,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey[500]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
