import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class WeeklyCheckIn extends StatefulWidget {
  const WeeklyCheckIn({Key? key}) : super(key: key);
  @override
  State<WeeklyCheckIn> createState() => _WeeklyCheckInState();
}

class _WeeklyCheckInState extends State<WeeklyCheckIn> {
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _mood;
  String? _energyLevel;
  String? _planAdherence;
  bool _loading = false;
  bool _submitted = false;

  final _moods = ['😄 Great', '🙂 Good', '😐 Okay', '😕 Low', '😞 Struggling'];
  final _energyOptions = ['⚡ High Energy', '🔋 Normal', '😴 Low Energy', '🛌 Exhausted'];
  final _adherenceOptions = ['Strictly (100%)', 'Mostly (75%)', 'Partially (50%)', 'Struggled (<50%)'];

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_weightCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your current weight'),
      ));
      return;
    }
    if (_mood == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select your mood'),
      ));
      return;
    }
    setState(() => _loading = true);
    final uid = FirebaseService.instance.currentUser!.uid;
    try {
      await FirebaseService.instance.weeklyUpdates.add({
        'clientId': uid,
        'weightKg': double.tryParse(_weightCtrl.text) ?? 0,
        'mood': _mood,
        'energyLevel': _energyLevel ?? '',
        'planAdherence': _planAdherence ?? '',
        'notes': _notesCtrl.text.trim(),
        'adminNotes': '',
        'submittedAt': FieldValue.serverTimestamp(),
      });
      // Update current weight in client profile
      await FirebaseService.instance.clients.doc(uid).set({
        'weightKg': double.tryParse(_weightCtrl.text) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() {
        _submitted = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit. Please try again: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Weekly Check-in'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() => Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade500, size: 48),
              ),
              SizedBox(height: 3.h),
              Text('Check-in Submitted! 🎉',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900)),
              SizedBox(height: 1.h),
              Text(
                'Great job staying consistent! Your dietician will review your update.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _submitted = false;
                    _weightCtrl.clear();
                    _notesCtrl.clear();
                    _mood = null;
                    _energyLevel = null;
                    _planAdherence = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Submit Another'),
              ),
            ],
          ),
        ),
      );

  Widget _buildForm() => ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _sectionCard(
            title: '⚖️ Current Weight',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '68.5',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              width: 2)),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.5.h),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Text('kg',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700)),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          _sectionCard(
            title: '😊 How are you feeling this week?',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((m) => _chipButton(m, _mood == m, () {
                    setState(() => _mood = m);
                  })).toList(),
            ),
          ),
          SizedBox(height: 2.h),
          _sectionCard(
            title: '⚡ Energy Level',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _energyOptions
                  .map((e) => _chipButton(e, _energyLevel == e, () {
                        setState(() => _energyLevel = e);
                      }))
                  .toList(),
            ),
          ),
          SizedBox(height: 2.h),
          _sectionCard(
            title: '🥗 Diet Plan Adherence',
            child: Column(
              children: _adherenceOptions.map((a) {
                final selected = _planAdherence == a;
                return GestureDetector(
                  onTap: () => setState(() => _planAdherence = a),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.lightTheme.colorScheme.primary
                              .withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : Colors.grey.shade200,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : Colors.grey.shade400,
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Text(a,
                            style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selected
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : Colors.grey.shade800)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 2.h),
          _sectionCard(
            title: '💬 Additional Notes',
            child: TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Share anything — challenges, questions, improvements...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        width: 2)),
                contentPadding: EdgeInsets.all(3.w),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('📤 Submit Weekly Check-in',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: 3.h),
        ],
      );

  Widget _sectionCard({required String title, required Widget child}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            SizedBox(height: 1.5.h),
            child,
          ],
        ),
      );

  Widget _chipButton(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.lightTheme.colorScheme.primary
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13)),
        ),
      );
}
