import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sizer/sizer.dart';

import '../../services/firebase_service.dart';
import '../../config/secrets.dart';
import '../../theme/app_theme.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class MealEntry {
  String name;
  String quantity;
  String calories;
  MealEntry({this.name = '', this.quantity = '', this.calories = ''});

  Map<String, dynamic> toMap() =>
      {'name': name, 'quantity': quantity, 'calories': calories};

  factory MealEntry.fromMap(Map<String, dynamic> m) => MealEntry(
        name: m['name'] ?? '',
        quantity: m['quantity'] ?? '',
        calories: m['calories'] ?? '',
      );
}

class DayPlan {
  String day;
  List<MealEntry> breakfast;
  List<MealEntry> midMorning;
  List<MealEntry> lunch;
  List<MealEntry> eveningSnack;
  List<MealEntry> dinner;

  DayPlan({
    required this.day,
    List<MealEntry>? breakfast,
    List<MealEntry>? midMorning,
    List<MealEntry>? lunch,
    List<MealEntry>? eveningSnack,
    List<MealEntry>? dinner,
  })  : breakfast = breakfast ?? [],
        midMorning = midMorning ?? [],
        lunch = lunch ?? [],
        eveningSnack = eveningSnack ?? [],
        dinner = dinner ?? [];

  Map<String, dynamic> toMap() => {
        'day': day,
        'breakfast': breakfast.map((e) => e.toMap()).toList(),
        'midMorning': midMorning.map((e) => e.toMap()).toList(),
        'lunch': lunch.map((e) => e.toMap()).toList(),
        'eveningSnack': eveningSnack.map((e) => e.toMap()).toList(),
        'dinner': dinner.map((e) => e.toMap()).toList(),
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdminDietPlanCreator extends StatefulWidget {
  const AdminDietPlanCreator({Key? key}) : super(key: key);

  @override
  State<AdminDietPlanCreator> createState() => _AdminDietPlanCreatorState();
}

class _AdminDietPlanCreatorState extends State<AdminDietPlanCreator> {
  // Step: 0=select client, 1=generating/editing, 2=done
  int _step = 0;

  // Client selection
  String? _selectedClientId;
  Map<String, dynamic>? _selectedClientProfile;
  List<Map<String, dynamic>> _clients = [];
  bool _loadingClients = true;

  // Plan
  String _planTitle = '';
  String _planNotes = '';
  List<DayPlan> _weekPlan = [];
  bool _generating = false;
  bool _saving = false;

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      // Query clients collection directly — works regardless of role field in users
      final clientsSnap = await FirebaseService.instance.clients.get();

      final List<Map<String, dynamic>> list = [];
      for (final doc in clientsSnap.docs) {
        final clientDocData = doc.data();
        final entry = <String, dynamic>{};
        entry['uid'] = doc.id;
        // Health profile data lives directly in the clients doc
        entry['profile'] = clientDocData;

        // Fetch display info from users collection
        final userSnap = await FirebaseService.instance.users.doc(doc.id).get();
        if (userSnap.exists) {
          final ud = userSnap.data()!;
          entry['email'] = ud['email'] ?? '';
          entry['phone'] = ud['phone'] ?? '';
          entry['displayName'] = ud['displayName'] ?? ud['name'] ?? '';
        } else {
          entry['email'] = clientDocData['email'] ?? '';
          entry['phone'] = clientDocData['phone'] ?? '';
          entry['displayName'] = '';
        }
        list.add(entry);
      }

      if (mounted) setState(() {
        _clients = list;
        _loadingClients = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingClients = false);
    }
  }

  // ─── Gemini generation ─────────────────────────────────────────────────────

  Future<void> _generateWithGemini() async {
    if (_selectedClientProfile == null) return;
    setState(() => _generating = true);

    final profile = _selectedClientProfile!;

    final age = profile['age'] ?? 'unknown';
    final weight = profile['weightKg'] ?? 'unknown';
    final height = profile['heightCm'] ?? 'unknown';
    final gender = profile['gender'] ?? 'unknown';
    final goal = profile['goal'] ?? 'weight loss';
    final activity = profile['activityLevel'] ?? 1.0;
    final medicalConditions =
        (profile['medicalConditions'] as List?)?.join(', ') ?? 'none';
    final dietaryRestrictions =
        (profile['dietaryRestrictions'] as List?)?.join(', ') ?? 'none';
    final cuisines =
        (profile['cuisines'] as List?)?.join(', ') ?? 'Indian';

    final prompt = '''
You are an expert Indian dietician. Create a personalised 7-day diet plan for a client.

CLIENT PROFILE:
- Age: $age years
- Gender: $gender
- Weight: $weight kg
- Height: $height cm
- Goal: $goal
- Activity level: $activity (1=sedentary, 2=lightly active, 3=moderately active, 4=very active)
- Medical conditions: $medicalConditions
- Dietary restrictions: $dietaryRestrictions
- Preferred cuisines: $cuisines

INSTRUCTIONS:
1. Create a 7-day plan with Day 1 to Day 7.
2. Each day must have: Breakfast, Mid-Morning Snack, Lunch, Evening Snack, Dinner.
3. Each meal must have 2-4 food items.
4. Each food item must include: name, quantity (e.g. "1 cup", "2 rotis"), approximate calories.
5. Focus on Indian foods — dal, sabzi, roti, rice, curd, fruits, nuts, etc.
6. Account for the medical conditions and dietary restrictions strictly.
7. Keep it practical and easy to follow for a home cook in India.

Respond ONLY with valid JSON in this exact format, no markdown, no explanation:
{
  "planTitle": "7-Day Diet Plan for [Goal]",
  "notes": "Brief 1-2 line note for the client",
  "days": [
    {
      "day": "Day 1",
      "breakfast": [{"name": "...", "quantity": "...", "calories": "..."}],
      "midMorning": [{"name": "...", "quantity": "...", "calories": "..."}],
      "lunch": [{"name": "...", "quantity": "...", "calories": "..."}],
      "eveningSnack": [{"name": "...", "quantity": "...", "calories": "..."}],
      "dinner": [{"name": "...", "quantity": "...", "calories": "..."}]
    }
  ]
}
''';

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppSecrets.geminiApiKey,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      // Extract JSON from response
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) throw Exception('Invalid JSON');

      final jsonStr = text.substring(jsonStart, jsonEnd + 1);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final days = (data['days'] as List).map((d) {
        final dm = d as Map<String, dynamic>;
        return DayPlan(
          day: dm['day'] ?? '',
          breakfast: _parseItems(dm['breakfast']),
          midMorning: _parseItems(dm['midMorning']),
          lunch: _parseItems(dm['lunch']),
          eveningSnack: _parseItems(dm['eveningSnack']),
          dinner: _parseItems(dm['dinner']),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _weekPlan = days;
          _planTitle = data['planTitle'] ?? '7-Day Diet Plan';
          _planNotes = data['notes'] ?? '';
          _titleController.text = _planTitle;
          _notesController.text = _planNotes;
          _step = 1;
          _generating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gemini error: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  List<MealEntry> _parseItems(dynamic items) {
    if (items == null) return [];
    return (items as List)
        .map((i) => MealEntry.fromMap(i as Map<String, dynamic>))
        .toList();
  }

  // ─── Save and push to client ───────────────────────────────────────────────

  Future<void> _sendToClient() async {
    if (_selectedClientId == null || _weekPlan.isEmpty) return;
    setState(() => _saving = true);

    try {
      await FirebaseService.instance.plans.add({
        'clientId': _selectedClientId,
        'title': _titleController.text.trim(),
        'notes': _notesController.text.trim(),
        'type': 'AI Generated',
        'weekPlan': _weekPlan.map((d) => d.toMap()).toList(),
        'uploadedAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
        'format': 'structured',
      });

      if (mounted) {
        setState(() {
          _saving = false;
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send plan: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Create Diet Plan'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_step == 1)
            TextButton.icon(
              onPressed: _generating ? null : _generateWithGemini,
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              label: const Text('Regenerate',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _step == 2 ? _buildSuccess() : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Progress steps
        _buildStepBar(),

        Expanded(
          child: _step == 0
              ? _buildClientSelector()
              : _buildPlanEditor(),
        ),

        // Bottom action
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildStepBar() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.primary,
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
      child: Row(
        children: [
          _stepDot(1, 'Select Client', _step >= 0),
          Expanded(
            child: Container(
              height: 2,
              color: _step >= 1
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
            ),
          ),
          _stepDot(2, 'Edit Plan', _step >= 1),
          Expanded(
            child: Container(
              height: 2,
              color: _step >= 2
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
            ),
          ),
          _stepDot(3, 'Send', _step >= 2),
        ],
      ),
    );
  }

  Widget _stepDot(int n, String label, bool active) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.white : Colors.white.withOpacity(0.3),
            ),
            child: Center(
              child: Text('$n',
                  style: TextStyle(
                      color: active
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      );

  // ─── Step 0: Select client ─────────────────────────────────────────────────

  Widget _buildClientSelector() {
    if (_loadingClients) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clients.isEmpty) {
      return Center(
        child: Text('No clients found.',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _clients.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
      itemBuilder: (context, i) {
        final client = _clients[i];
        final uid = client['uid'] as String;
        final email = (client['email'] as String?) ?? '';
        final phone = (client['phone'] as String?) ?? '';
        final displayName = (client['displayName'] as String?) ?? '';
        final profile = client['profile'] as Map<String, dynamic>?;
        final isSelected = _selectedClientId == uid;

        final name = profile != null
            ? '${profile['gender'] ?? ''} • ${profile['age'] ?? '?'}y • ${profile['weightKg'] ?? '?'}kg'
            : 'No profile yet';
        final goal = profile?['goal'] as String? ?? 'Not set';

        return GestureDetector(
          onTap: () => setState(() {
            _selectedClientId = uid;
            _selectedClientProfile = profile;
          }),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.primary
                              .withOpacity(0.12),
                          blurRadius: 8)
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded,
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                      size: 24),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isNotEmpty
                            ? displayName
                            : (email.isNotEmpty ? email : phone),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty && displayName.isNotEmpty)
                        Text(email,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      SizedBox(height: 3),
                      Text(name,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                      Text('Goal: $goal',
                          style: TextStyle(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: AppTheme.lightTheme.colorScheme.primary, size: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Step 1: Plan editor ───────────────────────────────────────────────────

  Widget _buildPlanEditor() {
    if (_generating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 3.h),
            Text('Gemini is creating the plan...',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey.shade700)),
            SizedBox(height: 1.h),
            Text('Analysing client profile & crafting meals',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan title & notes
          _sectionHeader('Plan Details'),
          TextField(
            controller: _titleController,
            decoration: _inputDec('Plan Title'),
            onChanged: (v) => _planTitle = v,
          ),
          SizedBox(height: 1.5.h),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: _inputDec('Notes for client (optional)'),
            onChanged: (v) => _planNotes = v,
          ),
          SizedBox(height: 3.h),

          _sectionHeader('7-Day Meal Plan'),
          SizedBox(height: 1.h),

          ...List.generate(_weekPlan.length, (i) {
            return _DayCard(
              dayPlan: _weekPlan[i],
              onChanged: () => setState(() {}),
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: EdgeInsets.only(bottom: 1.h),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF1a1a1a))),
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  // ─── Step 2: Success ───────────────────────────────────────────────────────

  Widget _buildSuccess() => Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade500, size: 52),
              ),
              SizedBox(height: 3.h),
              const Text('Plan Sent! 🎉',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 1.h),
              Text(
                'The diet plan has been pushed to your client. They can view it now in the My Diet Plan section.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _step = 0;
                    _selectedClientId = null;
                    _selectedClientProfile = null;
                    _weekPlan = [];
                    _titleController.clear();
                    _notesController.clear();
                  });
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Another Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: 6.w, vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 2.h),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Dashboard',
                    style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.primary)),
              ),
            ],
          ),
        ),
      );

  // ─── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 3.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: _step == 0
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedClientId != null && !_generating)
                    ? _generateWithGemini
                    : null,
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(
                  _generating
                      ? 'Generating...'
                      : 'Generate Plan with Gemini AI',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            )
          : Row(
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _step = 0),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 1.8.h, horizontal: 4.w),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(
                        color: AppTheme.lightTheme.colorScheme.primary),
                  ),
                  child: Text('← Back',
                      style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (_weekPlan.isNotEmpty && !_saving) ? _sendToClient : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 20),
                    label: Text(
                      _saving ? 'Sending...' : 'Send to Client',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Day Card widget ──────────────────────────────────────────────────────────

class _DayCard extends StatefulWidget {
  final DayPlan dayPlan;
  final VoidCallback onChanged;
  const _DayCard({required this.dayPlan, required this.onChanged});

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  static const _mealColors = {
    'Breakfast': Color(0xFF4CAF50),
    'Mid-Morning': Color(0xFF2196F3),
    'Lunch': Color(0xFFFF9800),
    'Evening Snack': Color(0xFF9C27B0),
    'Dinner': Color(0xFFF44336),
  };

  @override
  Widget build(BuildContext context) {
    final plan = widget.dayPlan;
    final allMeals = {
      'Breakfast': plan.breakfast,
      'Mid-Morning': plan.midMorning,
      'Lunch': plan.lunch,
      'Evening Snack': plan.eveningSnack,
      'Dinner': plan.dinner,
    };

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Day header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: const Color(0xFF61b239),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 2.w),
                  Text(
                    plan.day,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: allMeals.entries
                    .map((entry) => _MealSection(
                          mealName: entry.key,
                          items: entry.value,
                          color: _mealColors[entry.key] ?? Colors.grey,
                          onChanged: widget.onChanged,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Meal section ─────────────────────────────────────────────────────────────

class _MealSection extends StatelessWidget {
  final String mealName;
  final List<MealEntry> items;
  final Color color;
  final VoidCallback onChanged;
  const _MealSection(
      {required this.mealName,
      required this.items,
      required this.color,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 2.w),
              Text(mealName,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: color)),
            ],
          ),
          SizedBox(height: 0.8.h),
          ...items.map((item) => _EditableItem(
                item: item,
                accentColor: color,
                onChanged: onChanged,
              )),
          // Add item button
          GestureDetector(
            onTap: () {
              items.add(MealEntry());
              onChanged();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 0.8.h),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 16, color: color.withOpacity(0.6)),
                  SizedBox(width: 1.w),
                  Text('Add item',
                      style: TextStyle(
                          color: color.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Editable item row ────────────────────────────────────────────────────────

class _EditableItem extends StatelessWidget {
  final MealEntry item;
  final Color accentColor;
  final VoidCallback onChanged;
  const _EditableItem(
      {required this.item,
      required this.accentColor,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 0.8.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _inlineField(
              value: item.name,
              hint: 'Food item',
              onChanged: (v) {
                item.name = v;
                onChanged();
              },
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 3,
            child: _inlineField(
              value: item.quantity,
              hint: 'Qty',
              onChanged: (v) {
                item.quantity = v;
                onChanged();
              },
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 2,
            child: _inlineField(
              value: item.calories,
              hint: 'kcal',
              onChanged: (v) {
                item.calories = v;
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineField(
          {required String value,
          required String hint,
          required ValueChanged<String> onChanged}) =>
      TextFormField(
        initialValue: value,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: InputBorder.none,
        ),
      );
}
