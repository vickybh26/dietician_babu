import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/client_profile_service.dart';

/// Tab 3 — Progress Tracker
/// Shows weight trend chart + log of admin-entered progress entries
/// Also pulls weight from client weekly check-ins.
class ProgressTrackerTab extends StatefulWidget {
  final String clientId;
  const ProgressTrackerTab({super.key, required this.clientId});

  @override
  State<ProgressTrackerTab> createState() => _ProgressTrackerTabState();
}

class _ProgressTrackerTabState extends State<ProgressTrackerTab> {
  // 0 = Progress Entries (admin), 1 = Weekly Check-ins (client)
  int _selectedSource = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: _selectedSource == 0
              ? _buildProgressEntries()
              : _buildWeeklyCheckins(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Text('Progress Tracker',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900])),
          const Spacer(),

          // Source toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toggleBtn('Measurements', 0),
                _toggleBtn('Check-ins', 1),
              ],
            ),
          ),

          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showAddEntryDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, int index) {
    final selected = _selectedSource == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSource = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[600])),
      ),
    );
  }

  Widget _buildProgressEntries() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ClientProfileService.streamProgressEntries(widget.clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entries.isNotEmpty) ...[
                _buildWeightChart(entries),
                const SizedBox(height: 24),
              ],
              _buildEntriesList(entries),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeightChart(List<Map<String, dynamic>> entries) {
    // Build data points (chronological order)
    final chronological = List<Map<String, dynamic>>.from(entries)
      ..sort((a, b) {
        final aTs = a['entryDate'] ?? a['recordedAt'];
        final bTs = b['entryDate'] ?? b['recordedAt'];
        if (aTs == null || bTs == null) return 0;
        return (aTs as Timestamp).compareTo(bTs as Timestamp);
      });

    final spots = <FlSpot>[];
    for (int i = 0; i < chronological.length; i++) {
      final w = (chronological[i]['weightKg'] as num?)?.toDouble();
      if (w != null && w > 0) spots.add(FlSpot(i.toDouble(), w));
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFF1976D2), size: 18),
              const SizedBox(width: 8),
              Text('Weight Trend',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800])),
              const Spacer(),
              Text('${spots.last.y.toStringAsFixed(1)} kg (latest)',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey[100]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: spots.length <= 10,
                      reservedSize: 24,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= chronological.length) {
                          return const SizedBox.shrink();
                        }
                        final ts = chronological[idx]['entryDate'] ??
                            chronological[idx]['recordedAt'];
                        if (ts == null) return const SizedBox.shrink();
                        final dt = (ts as Timestamp).toDate();
                        return Text(
                          DateFormat('d/M').format(dt),
                          style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[500]),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF1976D2),
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1976D2).withOpacity(0.08),
                    ),
                    dotData: FlDotData(
                      show: spots.length <= 15,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                              radius: 3,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFF1976D2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) {
      return _buildEmpty('No progress entries yet',
          'Add manual measurements to track this client\'s progress.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Measurement Log (${entries.length})',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800])),
        const SizedBox(height: 12),
        ...entries.map((e) => _EntryCard(
              entry: e,
              clientId: widget.clientId,
            )),
      ],
    );
  }

  Widget _buildWeeklyCheckins() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ClientProfileService.streamWeeklyCheckins(widget.clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final checkins = snapshot.data ?? [];

        if (checkins.isEmpty) {
          return _buildEmpty('No check-ins yet',
              'This client hasn\'t submitted any weekly check-ins.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: checkins.length,
          itemBuilder: (context, i) => _CheckinCard(checkin: checkins[i]),
        );
      },
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title,
              style:
                  GoogleFonts.inter(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text(subtitle,
              style:
                  GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showAddEntryDialog() {
    final weightCtrl = TextEditingController();
    final bmiCtrl = TextEditingController();
    final waistCtrl = TextEditingController();
    final hipCtrl = TextEditingController();
    final chestCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime entryDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Progress Entry',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: entryDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => entryDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Entry Date',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: Icon(Icons.calendar_today, size: 16)),
                    child: Text(DateFormat('dd MMM yyyy').format(entryDate)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _dialogField('Weight (kg)', weightCtrl,
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _dialogField('BMI',bmiCtrl,
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _dialogField('Waist (cm)', waistCtrl,
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _dialogField('Hip (cm)', hipCtrl,
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                _dialogField('Chest (cm)', chestCtrl,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _dialogField('Notes', notesCtrl, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (weightCtrl.text.isEmpty) return;
                await ClientProfileService.addProgressEntry(
                    widget.clientId, {
                  'weightKg': double.tryParse(weightCtrl.text) ?? 0,
                  'bmi': double.tryParse(bmiCtrl.text),
                  'waistCm': double.tryParse(waistCtrl.text),
                  'hipCm': double.tryParse(hipCtrl.text),
                  'chestCm': double.tryParse(chestCtrl.text),
                  'notes': notesCtrl.text.trim(),
                  'entryDate': Timestamp.fromDate(entryDate),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Entry added!')));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

// ── Progress Entry Card ───────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String clientId;

  const _EntryCard({required this.entry, required this.clientId});

  String _formatDate(dynamic ts) {
    if (ts == null) return 'N/A';
    try {
      final dt = (ts as Timestamp).toDate();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final weight = entry['weightKg']?.toString() ?? '—';
    final bmi = entry['bmi']?.toString() ?? '—';
    final waist = entry['waistCm']?.toString() ?? '—';
    final hip = entry['hipCm']?.toString() ?? '—';
    final notes = entry['notes'] as String? ?? '';
    final date = _formatDate(entry['entryDate'] ?? entry['recordedAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(date,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final id = entry['id'] as String?;
                  if (id == null) return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Entry'),
                      content: const Text('Are you sure?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ClientProfileService.deleteProgressEntry(clientId, id);
                  }
                },
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _stat('Weight', '$weight kg', Icons.monitor_weight_outlined, Colors.blue),
              _stat('BMI', bmi, Icons.calculate_outlined, Colors.purple),
              _stat('Waist', '$waist cm', Icons.straighten_outlined, Colors.orange),
              _stat('Hip', '$hip cm', Icons.straighten_outlined, Colors.teal),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(notes,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text('$label: ',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
      ],
    );
  }
}

// ── Weekly Check-in Card ──────────────────────────────────────────────────────

class _CheckinCard extends StatelessWidget {
  final Map<String, dynamic> checkin;

  const _CheckinCard({required this.checkin});

  String _formatDate(dynamic ts) {
    if (ts == null) return 'N/A';
    try {
      final dt = (ts as Timestamp).toDate();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return 'N/A';
    }
  }

  Color _moodColor(String? mood) {
    if (mood == null) return Colors.grey;
    if (mood.contains('Great') || mood.contains('Good')) return Colors.green;
    if (mood.contains('Struggling') || mood.contains('Low')) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_formatDate(checkin['submittedAt']),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const Spacer(),
              if (checkin['mood'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _moodColor(checkin['mood']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(checkin['mood'],
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _moodColor(checkin['mood']))),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            children: [
              _field('Weight', '${checkin['weightKg'] ?? '—'} kg'),
              _field('Energy', checkin['energyLevel'] ?? '—'),
              _field('Adherence', checkin['planAdherence'] ?? '—'),
            ],
          ),
          if ((checkin['notes'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(checkin['notes'],
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
              text: value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}
