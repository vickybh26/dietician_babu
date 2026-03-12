import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/client_profile_service.dart';

/// Tab 1 — Personal Info + Health Profile
/// Reads from users/{uid} and clients/{uid}, writes back via ClientProfileService.
class PersonalInfoTab extends StatefulWidget {
  final String clientId;
  final Map<String, dynamic> profile;
  final VoidCallback onUpdated;

  const PersonalInfoTab({
    super.key,
    required this.clientId,
    required this.profile,
    required this.onUpdated,
  });

  @override
  State<PersonalInfoTab> createState() => _PersonalInfoTabState();
}

class _PersonalInfoTabState extends State<PersonalInfoTab> {
  bool _editing = false;
  bool _saving = false;

  // Personal info controllers
  late final _nameCtrl = TextEditingController();
  late final _emailCtrl = TextEditingController();
  late final _phoneCtrl = TextEditingController();
  late final _dobCtrl = TextEditingController();

  // Health profile controllers
  late final _heightCtrl = TextEditingController();
  late final _weightCtrl = TextEditingController();
  late final _targetCalCtrl = TextEditingController();
  late final _targetWaterCtrl = TextEditingController();

  // Dropdowns
  String _gender = 'Male';
  String _activityLevel = 'Moderate';
  String _goal = 'Weight Loss';
  String _country = 'India';

  // Lists from profile
  List<String> _medicalConditions = [];
  List<String> _allergies = [];
  List<String> _foodPreferences = [];

  @override
  void initState() {
    super.initState();
    _loadFromProfile();
  }

  void _loadFromProfile() {
    final p = widget.profile;
    _nameCtrl.text = p['name'] ?? '';
    _emailCtrl.text = p['email'] ?? '';
    _phoneCtrl.text = p['phone'] ?? '';
    _dobCtrl.text = p['dateOfBirth'] ?? '';

    _heightCtrl.text = p['heightCm']?.toString() ?? p['height']?.toString() ?? '';
    _weightCtrl.text = p['weightKg']?.toString() ?? p['weight']?.toString() ?? '';
    _targetCalCtrl.text = p['targetCalories']?.toString() ?? '1800';
    _targetWaterCtrl.text = p['targetWaterMl']?.toString() ?? '2500';

    _gender = p['gender'] ?? 'Male';
    _activityLevel = p['activityLevel'] ?? 'Moderate';
    _goal = p['goal'] ?? 'Weight Loss';
    _country = p['country'] ?? 'India';

    _medicalConditions = List<String>.from(p['medicalConditions'] ?? []);
    _allergies = List<String>.from(p['allergies'] ?? []);
    _foodPreferences = List<String>.from(p['foodPreferences'] ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetCalCtrl.dispose();
    _targetWaterCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Update users collection (identity)
      await ClientProfileService.updatePersonalInfo(widget.clientId, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'dateOfBirth': _dobCtrl.text.trim(),
        'gender': _gender,
        'country': _country,
      });

      // Update clients collection (health data)
      await ClientProfileService.updateHealthProfile(widget.clientId, {
        'heightCm': double.tryParse(_heightCtrl.text) ?? 0,
        'weightKg': double.tryParse(_weightCtrl.text) ?? 0,
        'targetCalories': int.tryParse(_targetCalCtrl.text) ?? 1800,
        'targetWaterMl': int.tryParse(_targetWaterCtrl.text) ?? 2500,
        'activityLevel': _activityLevel,
        'goal': _goal,
        'medicalConditions': _medicalConditions,
        'allergies': _allergies,
        'foodPreferences': _foodPreferences,
      });

      widget.onUpdated();
      if (mounted) {
        setState(() { _editing = false; _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text('Personal & Health Details',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900])),
              const Spacer(),
              if (!_editing)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                  ),
                )
              else ...[
                TextButton(
                    onPressed: _saving
                        ? null
                        : () {
                            _loadFromProfile();
                            setState(() => _editing = false);
                          },
                    child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 16),
                  label: Text(_saving ? 'Saving…' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Two-column layout
          LayoutBuilder(builder: (context, constraints) {
            final twoCol = constraints.maxWidth > 700;
            return twoCol
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPersonalSection()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildHealthSection()),
                    ],
                  )
                : Column(children: [
                    _buildPersonalSection(),
                    const SizedBox(height: 24),
                    _buildHealthSection(),
                  ]);
          }),

          const SizedBox(height: 24),
          _buildListSection('Medical Conditions', _medicalConditions,
              Icons.medical_services_outlined, Colors.red[600]!,
              onAdd: (v) => setState(() => _medicalConditions.add(v)),
              onRemove: (v) => setState(() => _medicalConditions.remove(v))),

          const SizedBox(height: 16),
          _buildListSection('Allergies', _allergies,
              Icons.warning_amber_outlined, Colors.orange,
              onAdd: (v) => setState(() => _allergies.add(v)),
              onRemove: (v) => setState(() => _allergies.remove(v))),

          const SizedBox(height: 16),
          _buildListSection('Food Preferences', _foodPreferences,
              Icons.fastfood_outlined, Colors.green,
              onAdd: (v) => setState(() => _foodPreferences.add(v)),
              onRemove: (v) => setState(() => _foodPreferences.remove(v))),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _Card(
      title: 'Personal Information',
      icon: Icons.person_outlined,
      child: Column(
        children: [
          _field('Full Name', _nameCtrl, Icons.badge_outlined),
          const SizedBox(height: 12),
          _field('Email', _emailCtrl, Icons.email_outlined,
              readOnly: true), // email is auth — don't let admin change
          const SizedBox(height: 12),
          _field('Phone', _phoneCtrl, Icons.phone_outlined),
          const SizedBox(height: 12),
          _field('Date of Birth', _dobCtrl, Icons.cake_outlined,
              hint: 'DD/MM/YYYY'),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Gender',
            value: _gender,
            items: ['Male', 'Female', 'Other', 'Prefer not to say'],
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Country',
            value: _country,
            items: ['India', 'USA', 'UK', 'UAE', 'Australia', 'Canada', 'Other'],
            onChanged: (v) => setState(() => _country = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSection() {
    return _Card(
      title: 'Health Profile',
      icon: Icons.health_and_safety_outlined,
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _field('Height (cm)', _heightCtrl, Icons.height_outlined, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field('Weight (kg)', _weightCtrl, Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Target Calories', _targetCalCtrl, Icons.local_fire_department_outlined, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field('Target Water (ml)', _targetWaterCtrl, Icons.water_drop_outlined, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Goal',
            value: _goal,
            items: ['Weight Loss', 'Weight Gain', 'Maintenance', 'Muscle Building', 'General Wellness', 'Disease Management'],
            onChanged: (v) => setState(() => _goal = v!),
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Activity Level',
            value: _activityLevel,
            items: ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'],
            onChanged: (v) => setState(() => _activityLevel = v!),
          ),

          // BMI display (computed)
          if (_heightCtrl.text.isNotEmpty && _weightCtrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _bmiCard(),
            ),
        ],
      ),
    );
  }

  Widget _bmiCard() {
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    if (h <= 0 || w <= 0) return const SizedBox.shrink();
    final bmi = w / ((h / 100) * (h / 100));
    final category = bmi < 18.5
        ? 'Underweight'
        : bmi < 25
            ? 'Normal'
            : bmi < 30
                ? 'Overweight'
                : 'Obese';
    final color = bmi < 18.5
        ? Colors.blue
        : bmi < 25
            ? Colors.green
            : bmi < 30
                ? Colors.orange
                : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: color, size: 18),
          const SizedBox(width: 8),
          Text('BMI: ${bmi.toStringAsFixed(1)}',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Text(category,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    String title,
    List<String> items,
    IconData icon,
    Color color, {
    required Function(String) onAdd,
    required Function(String) onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontSize: 14)),
              const Spacer(),
              if (_editing)
                TextButton.icon(
                  onPressed: () => _showAddTagDialog(title, onAdd),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(foregroundColor: color),
                ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('None recorded',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500])),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: items
                  .map((item) => Chip(
                        label: Text(item,
                            style: GoogleFonts.inter(fontSize: 12)),
                        backgroundColor: color.withOpacity(0.08),
                        side: BorderSide(color: color.withOpacity(0.3)),
                        deleteIcon: _editing
                            ? Icon(Icons.close, size: 14, color: color)
                            : null,
                        onDeleted: _editing ? () => onRemove(item) : null,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  void _showAddTagDialog(String type, Function(String) onAdd) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $type', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Enter $type…',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onAdd(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Field helpers ─────────────────────────────────────────────────────────

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      readOnly: readOnly || !_editing,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: const OutlineInputBorder(),
        isDense: true,
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : null,
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    // Ensure value is in items
    final safeValue = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: safeValue,
      onChanged: _editing ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
    );
  }
}

// ── Shared card widget ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: const Color(0xFF1976D2)),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
          ]),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}
