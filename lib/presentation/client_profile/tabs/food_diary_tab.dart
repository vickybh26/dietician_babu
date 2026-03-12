import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/client_profile_service.dart';

/// Tab 6 — Food Diary
/// Stored in clients/{uid}/foodLogs/{id}
class FoodDiaryTab extends StatelessWidget {
  final String clientId;
  const FoodDiaryTab({super.key, required this.clientId});

  static const _mealTypes = [
    'Breakfast',
    'Mid-Morning Snack',
    'Lunch',
    'Evening Snack',
    'Dinner',
    'Other',
  ];

  static Color _mealColor(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return const Color(0xFF1976D2);
      case 'dinner':
        return Colors.purple;
      case 'mid-morning snack':
      case 'evening snack':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  static IconData _mealIcon(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny_outlined;
      case 'lunch':
        return Icons.lunch_dining_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      default:
        return Icons.coffee_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ClientProfileService.streamFoodLogs(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];

        // Group by date
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final log in logs) {
          final date = _parseDate(log['date']);
          final key = date != null
              ? DateFormat('yyyy-MM-dd').format(date)
              : 'Unknown';
          grouped.putIfAbsent(key, () => []).add(log);
        }
        final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, logs.length),
            if (logs.isEmpty)
              _buildEmpty()
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: sortedKeys.length,
                  itemBuilder: (ctx, i) {
                    final key = sortedKeys[i];
                    final dayLogs = grouped[key]!;
                    final totalCals = dayLogs.fold<int>(
                        0,
                        (sum, l) =>
                            sum + ((l['calories'] as num?)?.toInt() ?? 0));
                    return _DaySection(
                      dateKey: key,
                      logs: dayLogs,
                      totalCalories: totalCals,
                      clientId: clientId,
                      mealColor: _mealColor,
                      mealIcon: _mealIcon,
                    );
                  },
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
          Text(
            'Food Diary ($count entries)',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900]),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Entries logged by client via app or manually by admin.',
            child: Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
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
            Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No food diary entries',
                style: GoogleFonts.inter(
                    fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text(
                'Clients log meals from the app. Admin can also add entries.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

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

  void _showAddDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    String selectedMeal = 'Breakfast';
    final foodCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Add Food Entry',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date row
                  _labeledWidget(
                    'Date',
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat('dd MMM yyyy').format(selectedDate),
                          style: GoogleFonts.inter(fontSize: 13)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Meal type
                  _labeledWidget(
                    'Meal Type',
                    DropdownButtonFormField<String>(
                      value: selectedMeal,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                      items: _mealTypes
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedMeal = v!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: foodCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Food Item(s)',
                      hintText: 'e.g. 2 chapati, dal, salad',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  // Macros row
                  Row(
                    children: [
                      Expanded(
                          child: _numField(calCtrl, 'Calories', 'kcal')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _numField(proteinCtrl, 'Protein', 'g')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _numField(carbsCtrl, 'Carbs', 'g')),
                      const SizedBox(width: 8),
                      Expanded(child: _numField(fatCtrl, 'Fat', 'g')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
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
                if (foodCtrl.text.trim().isEmpty) return;
                await ClientProfileService.addFoodLog(clientId, {
                  'date': Timestamp.fromDate(DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day)),
                  'mealType': selectedMeal,
                  'foodItem': foodCtrl.text.trim(),
                  'calories': int.tryParse(calCtrl.text) ?? 0,
                  'protein': double.tryParse(proteinCtrl.text) ?? 0.0,
                  'carbs': double.tryParse(carbsCtrl.text) ?? 0.0,
                  'fat': double.tryParse(fatCtrl.text) ?? 0.0,
                  'notes': notesCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white),
              child: const Text('Save Entry'),
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

  Widget _numField(TextEditingController ctrl, String label, String suffix) =>
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      );
}

// ── Day Section ───────────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  final String dateKey;
  final List<Map<String, dynamic>> logs;
  final int totalCalories;
  final String clientId;
  final Color Function(String) mealColor;
  final IconData Function(String) mealIcon;

  const _DaySection({
    required this.dateKey,
    required this.logs,
    required this.totalCalories,
    required this.clientId,
    required this.mealColor,
    required this.mealIcon,
  });

  String _formatDateKey(String key) {
    if (key == 'Unknown') return 'Unknown Date';
    try {
      final dt = DateTime.parse(key);
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) return 'Today';
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day - 1) return 'Yesterday';
      return DateFormat('EEEE, dd MMM yyyy').format(dt);
    } catch (_) {
      return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Text(
                _formatDateKey(dateKey),
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700]),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_outlined,
                        size: 13, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text('$totalCalories kcal',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[700])),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...logs.map((log) => _FoodLogCard(
              log: log,
              clientId: clientId,
              mealColor: mealColor,
              mealIcon: mealIcon,
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Food Log Card ─────────────────────────────────────────────────────────────

class _FoodLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final String clientId;
  final Color Function(String) mealColor;
  final IconData Function(String) mealIcon;

  const _FoodLogCard({
    required this.log,
    required this.clientId,
    required this.mealColor,
    required this.mealIcon,
  });

  @override
  Widget build(BuildContext context) {
    final meal = log['mealType'] ?? 'Other';
    final color = mealColor(meal);
    final logId = log['id'] as String?;
    final foodItem = log['foodItem'] ?? '';
    final calories = (log['calories'] as num?)?.toInt() ?? 0;
    final protein = (log['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (log['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (log['fat'] as num?)?.toDouble() ?? 0.0;
    final notes = log['notes'] as String? ?? '';
    final submittedBy = log['submittedBy'] as String? ?? 'client';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
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
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(mealIcon(meal), size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(meal,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color)),
                        if (submittedBy == 'admin') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Admin entry',
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: Colors.grey[500])),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            if (logId == null) return;
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Entry'),
                                content: const Text(
                                    'Remove this food log entry?'),
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
                              await ClientProfileService.deleteFoodLog(
                                  clientId, logId);
                            }
                          },
                          icon: const Icon(Icons.delete_outline,
                              size: 15, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 24, minHeight: 24),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(foodItem,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800])),
                    const SizedBox(height: 6),
                    // Macros row
                    Wrap(
                      spacing: 12,
                      children: [
                        _macro('🔥', '$calories kcal', Colors.orange[700]!),
                        if (protein > 0)
                          _macro('💪', '${protein.toStringAsFixed(1)}g protein',
                              Colors.blue[700]!),
                        if (carbs > 0)
                          _macro('🌾', '${carbs.toStringAsFixed(1)}g carbs',
                              Colors.amber[700]!),
                        if (fat > 0)
                          _macro('🫙', '${fat.toStringAsFixed(1)}g fat',
                              Colors.grey[600]!),
                      ],
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(notes,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[500],
                              height: 1.3)),
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

  Widget _macro(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}
