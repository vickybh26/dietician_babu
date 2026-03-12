import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/client_profile_service.dart';

/// Tab 4 — Admin Notes (private dietician notes per client)
/// Stored in clients/{uid}/notes/{noteId}
class NotesTab extends StatelessWidget {
  final String clientId;
  const NotesTab({super.key, required this.clientId});

  static const _categories = [
    'General',
    'Consultation',
    'Dietary',
    'Medical',
    'Follow-up',
  ];

  static Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'consultation':
        return const Color(0xFF1976D2);
      case 'dietary':
        return Colors.green;
      case 'medical':
        return Colors.red;
      case 'follow-up':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'consultation':
        return Icons.video_call_outlined;
      case 'dietary':
        return Icons.restaurant_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'follow-up':
        return Icons.schedule_outlined;
      default:
        return Icons.note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ClientProfileService.streamNotes(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notes = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, notes.length),
            if (notes.isEmpty)
              _buildEmpty()
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: notes.length,
                  itemBuilder: (context, i) => _NoteCard(
                    note: notes[i],
                    clientId: clientId,
                    categories: _categories,
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
          Text('Private Notes ($count)',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900])),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Notes are private and only visible to admins.',
            child: Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showNoteDialog(context, null, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
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
            Icon(Icons.notes_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No notes yet',
                style: GoogleFonts.inter(
                    fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Keep private consultation and dietary notes here.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(
      BuildContext context, String? noteId, Map<String, dynamic>? existing) {
    final contentCtrl =
        TextEditingController(text: existing?['content'] ?? '');
    String selectedCategory = existing?['category'] ?? 'General';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(noteId == null ? 'Add Note' : 'Edit Note',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chips
                Text('Category',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _categories
                      .map((cat) => ChoiceChip(
                            label: Text(cat,
                                style: GoogleFonts.inter(fontSize: 12)),
                            selected: selectedCategory == cat,
                            selectedColor:
                                _categoryColor(cat).withOpacity(0.15),
                            side: BorderSide(
                                color: selectedCategory == cat
                                    ? _categoryColor(cat)
                                    : Colors.grey[300]!),
                            onSelected: (_) => setDialogState(
                                () => selectedCategory = cat),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Note content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (contentCtrl.text.trim().isEmpty) return;
                if (noteId == null) {
                  await ClientProfileService.addNote(
                      clientId, contentCtrl.text.trim(), selectedCategory);
                } else {
                  await ClientProfileService.updateNote(clientId, noteId,
                      contentCtrl.text.trim(), selectedCategory);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white),
              child: Text(noteId == null ? 'Save Note' : 'Update Note'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Note Card ────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final String clientId;
  final List<String> categories;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _NoteCard({
    required this.note,
    required this.clientId,
    required this.categories,
    required this.categoryColor,
    required this.categoryIcon,
  });

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as Timestamp).toDate();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = note['category'] ?? 'General';
    final color = categoryColor(category);
    final icon = categoryIcon(category);
    final content = note['content'] ?? '';
    final createdAt = _formatDate(note['createdAt']);
    final updatedAt = note['updatedAt'] != null &&
            note['updatedAt'] != note['createdAt']
        ? _formatDate(note['updatedAt'])
        : null;
    final noteId = note['id'] as String?;

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
            // Colored left border + icon
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
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
                        // Edit
                        IconButton(
                          onPressed: () {
                            if (noteId == null) return;
                            _showEditDialog(context, noteId, note);
                          },
                          icon: const Icon(Icons.edit_outlined,
                              size: 16, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                          tooltip: 'Edit',
                        ),
                        // Delete
                        IconButton(
                          onPressed: () async {
                            if (noteId == null) return;
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Note'),
                                content: const Text(
                                    'This note will be permanently deleted.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete',
                                          style:
                                              TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await ClientProfileService.deleteNote(
                                  clientId, noteId);
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
                    const SizedBox(height: 10),
                    Text(content,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[800],
                            height: 1.5)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(createdAt,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey[500])),
                        if (updatedAt != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.edit,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Edited: $updatedAt',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey[500])),
                        ],
                      ],
                    ),
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
      BuildContext context, String noteId, Map<String, dynamic> existing) {
    final contentCtrl =
        TextEditingController(text: existing['content'] ?? '');
    String selectedCategory = existing['category'] ?? 'General';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title:
              Text('Edit Note', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: categories
                      .map((cat) => ChoiceChip(
                            label:
                                Text(cat, style: GoogleFonts.inter(fontSize: 12)),
                            selected: selectedCategory == cat,
                            selectedColor:
                                categoryColor(cat).withOpacity(0.15),
                            onSelected: (_) =>
                                setDialogState(() => selectedCategory = cat),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Note content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (contentCtrl.text.trim().isEmpty) return;
                await ClientProfileService.updateNote(clientId, noteId,
                    contentCtrl.text.trim(), selectedCategory);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white),
              child: const Text('Update Note'),
            ),
          ],
        ),
      ),
    );
  }
}
