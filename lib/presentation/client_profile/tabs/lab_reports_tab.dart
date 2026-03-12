import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/client_profile_service.dart';

/// Tab 7 — Lab Reports
/// Stored in clients/{uid}/labReports/{id}
class LabReportsTab extends StatefulWidget {
  final String clientId;
  const LabReportsTab({super.key, required this.clientId});

  @override
  State<LabReportsTab> createState() => LabReportsTabState();
}

class LabReportsTabState extends State<LabReportsTab> {
  // Expose showAddDialog for _LabReportCard's edit button
  void showEditDialog(BuildContext context, String reportId,
      Map<String, dynamic> existing) =>
      _showAddDialog(context, reportId: reportId, existing: existing);

  static const _testCategories = [
    'Blood Work',
    'Lipid Panel',
    'Thyroid Panel',
    'Liver Function',
    'Kidney Function',
    'HbA1c / Diabetes',
    'Vitamin & Mineral',
    'Hormones',
    'Other',
  ];

  static Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'blood work':
        return Colors.red;
      case 'lipid panel':
        return Colors.orange;
      case 'thyroid panel':
        return Colors.purple;
      case 'hba1c / diabetes':
        return Colors.blue;
      case 'liver function':
        return Colors.brown;
      case 'kidney function':
        return Colors.teal;
      case 'vitamin & mineral':
        return Colors.green;
      case 'hormones':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  static IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'blood work':
        return Icons.bloodtype_outlined;
      case 'lipid panel':
        return Icons.favorite_border;
      case 'thyroid panel':
        return Icons.psychology_outlined;
      case 'hba1c / diabetes':
        return Icons.monitor_outlined;
      case 'liver function':
      case 'kidney function':
        return Icons.medical_services_outlined;
      default:
        return Icons.science_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ClientProfileService.streamLabReports(widget.clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, reports.length),
            if (reports.isEmpty)
              _buildEmpty()
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: reports.length,
                  itemBuilder: (ctx, i) => _LabReportCard(
                    report: reports[i],
                    clientId: widget.clientId,
                    categories: _testCategories,
                    categoryColor: _categoryColor,
                    categoryIcon: _categoryIcon,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Text('Lab Reports ($count)',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900])),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No lab reports yet',
                style: GoogleFonts.inter(
                    fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Add blood work, lipid panels, and other test results.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, {String? reportId, Map<String, dynamic>? existing}) {
    DateTime selectedDate = existing != null && existing['date'] != null
        ? _parseDate(existing['date']) ?? DateTime.now()
        : DateTime.now();
    String selectedCategory = existing?['category'] ?? 'Blood Work';
    final testNameCtrl = TextEditingController(text: existing?['testName'] ?? '');
    final resultsCtrl = TextEditingController(text: existing?['results'] ?? '');
    final fileUrlCtrl = TextEditingController(text: existing?['fileUrl'] ?? '');
    final notesCtrl = TextEditingController(text: existing?['notes'] ?? '');
    // Key values list: [{name, value, unit, status}]
    final List<Map<String, TextEditingController>> keyValues =
        existing?['keyValues'] is List
            ? (existing!['keyValues'] as List)
                .map((kv) => {
                      'name': TextEditingController(text: kv['name'] ?? ''),
                      'value': TextEditingController(
                          text: kv['value']?.toString() ?? ''),
                      'unit': TextEditingController(text: kv['unit'] ?? ''),
                    })
                .toList()
            : [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            reportId == null ? 'Add Lab Report' : 'Edit Lab Report',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _labeledWidget(
                          'Date of Test',
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: GoogleFonts.inter(fontSize: 13)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2015),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 1)),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _labeledWidget(
                          'Category',
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10)),
                            items: _testCategories
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedCategory = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: testNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Test / Report Name',
                      hintText: 'e.g. Complete Blood Count (CBC)',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resultsCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Results Summary',
                      hintText:
                          'Paste the full report or key findings here…',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Key values (dynamic rows)
                  Row(
                    children: [
                      Text('Key Values',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600])),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setState(() => keyValues.add({
                              'name': TextEditingController(),
                              'value': TextEditingController(),
                              'unit': TextEditingController(),
                            })),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add Row'),
                        style:
                            TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                  ...keyValues.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final kv = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: kv['name'],
                              decoration: const InputDecoration(
                                hintText: 'Parameter',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: kv['value'],
                              decoration: const InputDecoration(
                                hintText: 'Value',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: kv['unit'],
                              decoration: const InputDecoration(
                                hintText: 'Unit',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => keyValues.removeAt(idx)),
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fileUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Report File URL (optional)',
                      hintText: 'https://…',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Dietician Notes / Interpretation',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
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
                if (testNameCtrl.text.trim().isEmpty) return;
                final kvData = keyValues
                    .where((kv) => kv['name']!.text.trim().isNotEmpty)
                    .map((kv) => {
                          'name': kv['name']!.text.trim(),
                          'value': kv['value']!.text.trim(),
                          'unit': kv['unit']!.text.trim(),
                        })
                    .toList();

                final data = {
                  'date': Timestamp.fromDate(DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day)),
                  'category': selectedCategory,
                  'testName': testNameCtrl.text.trim(),
                  'results': resultsCtrl.text.trim(),
                  'keyValues': kvData,
                  'fileUrl': fileUrlCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                };

                if (reportId == null) {
                  await ClientProfileService.addLabReport(widget.clientId, data);
                } else {
                  await ClientProfileService.updateLabReport(
                      widget.clientId, reportId, data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white),
              child: Text(reportId == null ? 'Save Report' : 'Update Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledWidget(String label, Widget child) => Column(
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

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    return null;
  }
}

// ── Lab Report Card ───────────────────────────────────────────────────────────

class _LabReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final String clientId;
  final List<String> categories;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _LabReportCard({
    required this.report,
    required this.clientId,
    required this.categories,
    required this.categoryColor,
    required this.categoryIcon,
  });

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final category = report['category'] ?? 'Other';
    final color = categoryColor(category);
    final icon = categoryIcon(category);
    final reportId = report['id'] as String?;
    final testName = report['testName'] ?? '';
    final results = report['results'] as String? ?? '';
    final fileUrl = report['fileUrl'] as String? ?? '';
    final notes = report['notes'] as String? ?? '';
    final date = _parseDate(report['date']);
    final keyValues = report['keyValues'];
    final List<Map<String, dynamic>> kvList = keyValues is List
        ? keyValues.map((e) => Map<String, dynamic>.from(e)).toList()
        : [];

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
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 15, color: color),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(category,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                        const Spacer(),
                        if (date != null)
                          Text(DateFormat('dd MMM yyyy').format(date),
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            if (reportId == null) return;
                            _showEdit(context, reportId, report);
                          },
                          icon: const Icon(Icons.edit_outlined,
                              size: 16, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () async {
                            if (reportId == null) return;
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Report'),
                                content: const Text(
                                    'Remove this lab report permanently?'),
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
                              await ClientProfileService.deleteLabReport(
                                  clientId, reportId);
                            }
                          },
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(testName,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900])),
                    // Key values table
                    if (kvList.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              decoration:
                                  BoxDecoration(color: Colors.grey[100]),
                              children: [
                                'Parameter',
                                'Value',
                                'Unit',
                              ]
                                  .map((h) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        child: Text(h,
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey[600])),
                                      ))
                                  .toList(),
                            ),
                            ...kvList.map((kv) => TableRow(
                                  children: [
                                    'name',
                                    'value',
                                    'unit',
                                  ]
                                      .map((k) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            child: Text(
                                                kv[k]?.toString() ?? '',
                                                style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.grey[800])),
                                          ))
                                      .toList(),
                                )),
                          ],
                        ),
                      ),
                    ],
                    if (results.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(results,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.5)),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes_outlined,
                                size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(notes,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (fileUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_file,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              fileUrl,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF1976D2),
                                  decoration: TextDecoration.underline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  void _showEdit(BuildContext context, String reportId,
      Map<String, dynamic> existing) {
    final tabState =
        context.findAncestorStateOfType<LabReportsTabState>();
    tabState?.showEditDialog(context, reportId, existing);
  }
}
