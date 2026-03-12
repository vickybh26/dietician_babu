import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/client_profile_service.dart';

/// Tab 8 — Documents
/// Stored in clients/{uid}/documents/{id}
/// Supports file URL links (Firebase Storage URLs or external).
class DocumentsTab extends StatelessWidget {
  final String clientId;
  const DocumentsTab({super.key, required this.clientId});

  static const _docTypes = [
    'Consent Form',
    'Prescription',
    'Lab Report',
    'Diet Chart',
    'Workout Plan',
    'Assessment Form',
    'Medical Certificate',
    'Other',
  ];

  static Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'consent form':
        return Colors.purple;
      case 'prescription':
        return const Color(0xFF1976D2);
      case 'lab report':
        return Colors.red;
      case 'diet chart':
        return Colors.green;
      case 'workout plan':
        return Colors.orange;
      case 'assessment form':
        return Colors.teal;
      case 'medical certificate':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'consent form':
        return Icons.assignment_outlined;
      case 'prescription':
        return Icons.medication_outlined;
      case 'lab report':
        return Icons.science_outlined;
      case 'diet chart':
        return Icons.restaurant_outlined;
      case 'workout plan':
        return Icons.fitness_center_outlined;
      case 'assessment form':
        return Icons.checklist_outlined;
      case 'medical certificate':
        return Icons.verified_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ClientProfileService.streamDocuments(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, docs.length),
            if (docs.isEmpty)
              _buildEmpty()
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) => _DocumentCard(
                    doc: docs[i],
                    clientId: clientId,
                    typeColor: _typeColor,
                    typeIcon: _typeIcon,
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
          Text('Documents ($count)',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900])),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Consent forms, prescriptions, uploaded files.',
            child: Icon(Icons.info_outline,
                size: 16, color: Colors.grey[400]),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.upload_file_outlined, size: 16),
            label: const Text('Add Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
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
            Icon(Icons.folder_open_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No documents yet',
                style: GoogleFonts.inter(
                    fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text(
                'Store consent forms, prescriptions, and other client files here.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    String selectedType = 'Consent Form';
    final nameCtrl = TextEditingController();
    final fileUrlCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Add Document',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type dropdown
                  _labeledWidget(
                    'Document Type',
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                      items: _docTypes
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Row(
                                children: [
                                  Icon(_typeIcon(t),
                                      size: 16,
                                      color: _typeColor(t)),
                                  const SizedBox(width: 8),
                                  Text(t),
                                ],
                              )))
                          .toList(),
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Document Name',
                      hintText: 'e.g. Consultation Consent Form - March 2026',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  _labeledWidget(
                    'Date',
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
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fileUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'File URL',
                      hintText: 'https://storage.googleapis.com/… or drive link',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
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
                if (nameCtrl.text.trim().isEmpty &&
                    fileUrlCtrl.text.trim().isEmpty) return;
                await ClientProfileService.addDocument(clientId, {
                  'type': selectedType,
                  'name': nameCtrl.text.trim().isNotEmpty
                      ? nameCtrl.text.trim()
                      : selectedType,
                  'date': Timestamp.fromDate(DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day)),
                  'fileUrl': fileUrlCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white),
              child: const Text('Save Document'),
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
}

// ── Document Card ─────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final String clientId;
  final Color Function(String) typeColor;
  final IconData Function(String) typeIcon;

  const _DocumentCard({
    required this.doc,
    required this.clientId,
    required this.typeColor,
    required this.typeIcon,
  });

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final type = doc['type'] ?? 'Other';
    final name = doc['name'] ?? type;
    final color = typeColor(type);
    final icon = typeIcon(type);
    final docId = doc['id'] as String?;
    final fileUrl = doc['fileUrl'] as String? ?? '';
    final notes = doc['notes'] as String? ?? '';
    final uploadedAt = _parseDate(doc['uploadedAt']);
    final docDate = _parseDate(doc['date']);
    final displayDate = uploadedAt ?? docDate;
    final uploadedBy = doc['uploadedBy'] as String? ?? 'admin';

    return Container(
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
      child: Stack(
        children: [
          // Top color accent
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 22, color: color),
                    ),
                    const Spacer(),
                    // Actions
                    if (fileUrl.isNotEmpty)
                      Tooltip(
                        message: 'Open file',
                        child: IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Opening: $fileUrl')),
                            );
                          },
                          icon: Icon(Icons.open_in_new,
                              size: 16, color: Colors.grey[500]),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 24, minHeight: 24),
                        ),
                      ),
                    Tooltip(
                      message: 'Delete',
                      child: IconButton(
                        onPressed: () async {
                          if (docId == null) return;
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Document'),
                              content: Text(
                                  'Remove "$name" permanently?'),
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
                            await ClientProfileService.deleteDocument(
                                clientId, docId);
                          }
                        },
                        icon: Icon(Icons.delete_outline,
                            size: 16, color: Colors.grey[500]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 24, minHeight: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(type,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
                const Spacer(),
                // Footer
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      displayDate != null
                          ? DateFormat('dd MMM yyyy').format(displayDate)
                          : '—',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                    const Spacer(),
                    if (fileUrl.isNotEmpty)
                      Icon(Icons.attach_file,
                          size: 12, color: Colors.grey[400]),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
