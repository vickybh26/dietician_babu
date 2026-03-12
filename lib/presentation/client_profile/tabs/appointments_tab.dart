import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/client_profile_service.dart';

/// Tab 5 — Appointments
/// Stored in top-level appointments/{id} with clientId field.
class AppointmentsTab extends StatefulWidget {
  final String clientId;
  const AppointmentsTab({super.key, required this.clientId});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  bool _showUpcoming = true;

  static const _types = [
    'Consultation',
    'Follow-up',
    'Diet Review',
    'Progress Review',
    'Emergency',
    'Other',
  ];

  static const _statuses = ['scheduled', 'completed', 'cancelled', 'no-show'];

  static Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'consultation':
        return const Color(0xFF1976D2);
      case 'follow-up':
        return Colors.teal;
      case 'diet review':
        return Colors.green;
      case 'progress review':
        return Colors.purple;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no-show':
        return Colors.orange;
      default:
        return const Color(0xFF1976D2);
    }
  }

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'consultation':
        return Icons.video_call_outlined;
      case 'follow-up':
        return Icons.schedule_outlined;
      case 'diet review':
        return Icons.restaurant_outlined;
      case 'progress review':
        return Icons.show_chart_outlined;
      case 'emergency':
        return Icons.emergency_outlined;
      default:
        return Icons.calendar_today_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ClientProfileService.streamAppointments(widget.clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final now = DateTime.now();

        final upcoming = all.where((a) {
          final date = _parseDate(a['date']);
          final status = (a['status'] ?? 'scheduled').toString().toLowerCase();
          return date != null &&
              (date.isAfter(now) || _isToday(date, now)) &&
              status != 'cancelled';
        }).toList();

        final past = all.where((a) {
          final date = _parseDate(a['date']);
          if (date == null) return true;
          final status = (a['status'] ?? 'scheduled').toString().toLowerCase();
          return date.isBefore(now) && !_isToday(date, now) ||
              status == 'cancelled';
        }).toList();

        final shown = _showUpcoming ? upcoming : past;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, upcoming.length, past.length),
            if (shown.isEmpty)
              _buildEmpty()
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: shown.length,
                  itemBuilder: (ctx, i) => _AppointmentCard(
                    appt: shown[i],
                    clientId: widget.clientId,
                    types: _types,
                    statuses: _statuses,
                    typeColor: _typeColor,
                    statusColor: _statusColor,
                    typeIcon: _typeIcon,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _isToday(DateTime date, DateTime now) =>
      date.year == now.year && date.month == now.month && date.day == now.day;

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) {
      try {
        return DateTime.parse(val);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Widget _buildHeader(BuildContext ctx, int upcomingCount, int pastCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toggleBtn('Upcoming ($upcomingCount)', true),
                _toggleBtn('Past ($pastCount)', false),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showApptDialog(context, null, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Appointment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool isUpcoming) {
    final selected = _showUpcoming == isUpcoming;
    return GestureDetector(
      onTap: () => setState(() => _showUpcoming = isUpcoming),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _showUpcoming
                  ? 'No upcoming appointments'
                  : 'No past appointments',
              style:
                  GoogleFonts.inter(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule consultations and follow-up sessions here.',
              style:
                  GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  void _showApptDialog(BuildContext context, String? apptId,
      Map<String, dynamic>? existing) {
    DateTime selectedDate =
        existing != null && existing['date'] != null
            ? (_parseDate(existing['date']) ?? DateTime.now())
            : DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = existing != null && existing['time'] != null
        ? _parseTime(existing['time'] as String? ?? '10:00')
        : const TimeOfDay(hour: 10, minute: 0);
    String selectedType = existing?['type'] ?? 'Consultation';
    String selectedStatus = existing?['status'] ?? 'scheduled';
    int duration = existing?['durationMins'] is int
        ? existing!['durationMins'] as int
        : 30;
    final notesCtrl =
        TextEditingController(text: existing?['notes'] ?? '');
    final outcomeCtrl =
        TextEditingController(text: existing?['outcome'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              apptId == null ? 'Schedule Appointment' : 'Edit Appointment',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date + Time row
                    Row(
                      children: [
                        Expanded(
                          child: _labeledWidget(
                            'Date',
                            OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                  DateFormat('dd MMM yyyy')
                                      .format(selectedDate),
                                  style: GoogleFonts.inter(fontSize: 13)),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedDate = picked);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _labeledWidget(
                            'Time',
                            OutlinedButton.icon(
                              icon: const Icon(Icons.access_time, size: 16),
                              label: Text(
                                  selectedTime.format(ctx),
                                  style: GoogleFonts.inter(fontSize: 13)),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedTime = picked);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Type + Duration row
                    Row(
                      children: [
                        Expanded(
                          child: _labeledWidget(
                            'Type',
                            DropdownButtonFormField<String>(
                              value: selectedType,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10)),
                              items: _types
                                  .map((t) => DropdownMenuItem(
                                      value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => selectedType = v!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 130,
                          child: _labeledWidget(
                            'Duration (mins)',
                            TextFormField(
                              initialValue: duration.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10)),
                              onChanged: (v) =>
                                  duration = int.tryParse(v) ?? 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (apptId != null) ...[
                      _labeledWidget(
                        'Status',
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10)),
                          items: _statuses
                              .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                      s[0].toUpperCase() + s.substring(1))))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedStatus = v!),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Agenda',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (apptId != null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: outcomeCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Outcome / Summary',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final dt = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  final data = {
                    'date': Timestamp.fromDate(dt),
                    'time':
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    'type': selectedType,
                    'status': selectedStatus,
                    'durationMins': duration,
                    'notes': notesCtrl.text.trim(),
                    if (apptId != null)
                      'outcome': outcomeCtrl.text.trim(),
                  };
                  if (apptId == null) {
                    await ClientProfileService.addAppointment(
                        widget.clientId, data);
                  } else {
                    await ClientProfileService.updateAppointment(
                        apptId, data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white),
                child: Text(
                    apptId == null ? 'Schedule' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _labeledWidget(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600])),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 10, minute: 0);
    return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 10,
        minute: int.tryParse(parts[1]) ?? 0);
  }
}

// ── Appointment Card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final String clientId;
  final List<String> types;
  final List<String> statuses;
  final Color Function(String) typeColor;
  final Color Function(String) statusColor;
  final IconData Function(String) typeIcon;

  const _AppointmentCard({
    required this.appt,
    required this.clientId,
    required this.types,
    required this.statuses,
    required this.typeColor,
    required this.statusColor,
    required this.typeIcon,
  });

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final type = appt['type'] ?? 'Consultation';
    final status = appt['status'] ?? 'scheduled';
    final color = typeColor(type);
    final sColor = statusColor(status);
    final apptId = appt['id'] as String?;
    final date = _parseDate(appt['date']);
    final time = appt['time'] as String? ?? '';
    final duration = appt['durationMins'] ?? 30;
    final notes = appt['notes'] as String? ?? '';
    final outcome = appt['outcome'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12)),
              ),
            ),
            // Date column
            Container(
              width: 72,
              padding: const EdgeInsets.all(12),
              alignment: Alignment.topCenter,
              child: date != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('MMM').format(date).toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 1)),
                        Text(DateFormat('d').format(date),
                            style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800])),
                        Text(DateFormat('EEE').format(date),
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey[500])),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(typeIcon(type), size: 15, color: color),
                        const SizedBox(width: 6),
                        Text(type,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[900])),
                        const SizedBox(width: 10),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              status[0].toUpperCase() + status.substring(1),
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: sColor)),
                        ),
                        const Spacer(),
                        // Actions
                        IconButton(
                          onPressed: () {
                            if (apptId == null) return;
                            _showEditDialog(context, apptId, appt);
                          },
                          icon: const Icon(Icons.edit_outlined,
                              size: 16, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () async {
                            if (apptId == null) return;
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title:
                                    const Text('Delete Appointment'),
                                content: const Text(
                                    'Remove this appointment permanently?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete',
                                          style: TextStyle(
                                              color: Colors.red))),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await ClientProfileService.deleteAppointment(
                                  apptId);
                            }
                          },
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('$time · $duration min',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(notes,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4)),
                    ],
                    if (outcome.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 14, color: Colors.green[700]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(outcome,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.green[800],
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, String apptId, Map<String, dynamic> existing) {
    // Reuse the parent's dialog via a callback approach
    final state =
        context.findAncestorStateOfType<_AppointmentsTabState>();
    state?._showApptDialog(context, apptId, existing);
  }
}
