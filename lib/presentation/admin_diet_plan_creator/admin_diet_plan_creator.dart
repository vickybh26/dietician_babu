import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/client_tags.dart';
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
  int _step = 0;

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final Set<String> _selectedTags = {};

  String? _selectedClientId;
  Map<String, dynamic>? _selectedClientProfile;
  List<Map<String, dynamic>> _clients = [];
  bool _loadingClients = true;
  bool _showClientList = false;

  List<DayPlan> _weekPlan = [];
  String _planTitle = '';
  String _planNotes = '';
  bool _generating = false;
  bool _saving = false;

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
      final clientsSnap = await FirebaseService.instance.clients.get();
      final List<Map<String, dynamic>> list = [];
      for (final doc in clientsSnap.docs) {
        final clientDocData = doc.data();
        final entry = <String, dynamic>{};
        entry['uid'] = doc.id;
        entry['profile'] = clientDocData;
        entry['tags'] = (clientDocData['tags'] as List?)
                ?.map((t) => t.toString())
                .toList() ??
            <String>[];

        final userSnap =
            await FirebaseService.instance.users.doc(doc.id).get();
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
      if (mounted) {
        setState(() {
          _clients = list;
          _loadingClients = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingClients = false);
    }
  }

  void _selectClient(String uid, Map<String, dynamic>? profile) {
    setState(() {
      _selectedClientId = uid;
      _selectedClientProfile = profile;
      _showClientList = false;
    });

    final clientEntry = _clients.firstWhere(
      (c) => c['uid'] == uid,
      orElse: () => {},
    );
    final clientTags = (clientEntry['tags'] as List<String>?) ?? [];
    if (clientTags.isNotEmpty) {
      setState(() {
        _selectedTags.clear();
        _selectedTags.addAll(clientTags);
      });
    }
  }

  Future<void> _loadFromLibrary() async {
    // Show a dialog to pick an existing plan
    final selectedPlan = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PlanPickerPopup(),
    );

    if (selectedPlan != null && mounted) {
      setState(() {
        _titleController.text = selectedPlan['title'] ?? '';
        _notesController.text = selectedPlan['notes'] ?? '';
        _selectedTags.clear();
        _selectedTags.addAll((selectedPlan['tags'] as List?)?.map((e) => e.toString()) ?? []);
        
        final weekData = selectedPlan['weekPlan'] as List?;
        if (weekData != null) {
          _weekPlan = weekData.map((d) => DayPlan(
            day: d['day'] ?? '',
            breakfast: _parseItems(d['breakfast']),
            midMorning: _parseItems(d['midMorning']),
            lunch: _parseItems(d['lunch']),
            eveningSnack: _parseItems(d['eveningSnack']),
            dinner: _parseItems(d['dinner']),
          )).toList();
          _step = 1;
        }
      });
    }
  }

  Future<void> _generateWithGemini() async {
    setState(() => _generating = true);

    final title = _titleController.text.trim();
    final tags = _selectedTags.toList();
    final profile = _selectedClientProfile;

    String promptSuffix;
    if (profile != null) {
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
      final clientTags = (profile['tags'] as List?)?.join(', ') ?? '';

      promptSuffix = '''
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
- Health tags: ${clientTags.isNotEmpty ? clientTags : 'general'}''';
    } else {
      final dietType = tags.contains('Non-Veg')
          ? 'Non-Vegetarian Indian'
          : tags.contains('Egg')
              ? 'Eggetarian Indian'
              : tags.contains('Vegan')
                  ? 'Vegan Indian'
                  : 'Vegetarian Indian';
      final goals = tags
          .where((t) => [
                'Weight Loss',
                'Weight Gain',
                'High Protein',
                'Diabetes',
                'Gluten Free',
                'Low Carb',
                'Heart Healthy',
                'High BP',
                'Thyroid',
                'PCOD/PCOS',
                'Cholesterol',
                'Keto',
                'Dairy Free',
                'High Fibre',
                'Maintenance',
              ].contains(t))
          .join(', ');

      promptSuffix = '''
CLIENT PROFILE:
- General healthy Indian adult
- Diet type: $dietType
- Focus goals: ${goals.isNotEmpty ? goals : 'Balanced nutrition and general health'}
- Cuisine: Indian''';
    }

    final tagList = tags.isNotEmpty ? tags.join(', ') : 'General';

    final prompt = '''
You are an expert Indian dietician. Create a personalised 7-day diet plan.

$promptSuffix

PLAN TAGS: $tagList
PLAN TITLE: ${title.isNotEmpty ? title : '7-Day Diet Plan'}

INSTRUCTIONS:
1. Create a 7-day plan with Day 1 to Day 7.
2. Each day must have: Breakfast, Mid-Morning Snack, Lunch, Evening Snack, Dinner.
3. Each meal must have 2-4 food items.
4. Each food item must include: name, quantity (e.g. "1 cup", "2 rotis"), approximate calories.
5. Focus on Indian foods — dal, sabzi, roti, rice, curd, fruits, nuts, etc.
6. Strictly follow the dietary restrictions implied by the tags:
   - Veg: no meat/fish/eggs
   - Vegan: no animal products including dairy/eggs
   - Non-Veg: can include chicken, fish, eggs
   - Gluten Free: no wheat/maida/roti — use rice, millets, sorghum instead
   - Dairy Free: no milk, curd, paneer, ghee
   - Keto / Low Carb: minimal rice/roti, high fat, moderate protein
7. If Diabetes or High BP tag: avoid sugar, white rice, refined flour, excess salt
8. If Heart Healthy or Cholesterol tag: low saturated fat, high fibre, omega-3 rich
9. If PCOD/PCOS or Thyroid tag: anti-inflammatory foods, low GI, avoid processed sugar
10. Keep it practical and easy for a home cook in India.

Respond ONLY with valid JSON in this exact format, no markdown, no explanation:
{
  "planTitle": "7-Day Diet Plan for [Goal]",
  "notes": "Brief 1-2 line note about this plan",
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
        model: 'gemini-2.0-flash',
        apiKey: AppSecrets.geminiApiKey,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

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

      final generatedTitle = data['planTitle'] ?? '7-Day Diet Plan';
      final generatedNotes = data['notes'] ?? '';

      if (mounted) {
        setState(() {
          _weekPlan = days;
          _planTitle = title.isNotEmpty ? title : generatedTitle;
          _planNotes = generatedNotes;
          if (_titleController.text.isEmpty) {
            _titleController.text = _planTitle;
          }
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

  Future<void> _savePlan() async {
    if (_weekPlan.isEmpty) return;
    setState(() => _saving = true);

    try {
      final docRef = await FirebaseService.instance.plans.add({
        if (_selectedClientId != null) 'clientId': _selectedClientId,
        'title': _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : _planTitle,
        'notes': _notesController.text.trim(),
        'tags': _selectedTags.toList(),
        'type': 'Structured Plan', // FIX: Removed "AI Generated"
        'weekPlan': _weekPlan.map((d) => d.toMap()).toList(),
        'uploadedAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
        'format': 'structured',
      });

      if (_selectedClientId != null) {
        await FirebaseService.instance.clients.doc(_selectedClientId).set({
          'currentPlanId': docRef.id,
          'planAssignedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

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
          content: Text('Failed to save plan: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

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
          if (_step == 0)
            TextButton.icon(
              onPressed: _loadFromLibrary,
              icon: const Icon(Icons.library_books, color: Colors.white, size: 18),
              label: const Text('Load from Library', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          if (_step == 1)
            TextButton.icon(
              onPressed: _generating ? null : _generateWithGemini,
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              label: const Text('Regenerate', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _step == 2 ? _buildSuccess() : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildStepBar(),
        Expanded(
          child: _step == 0 ? _buildPlanSetup() : _buildPlanEditor(),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildStepBar() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.primary,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _stepDot(1, 'Plan Setup', _step >= 0),
          Expanded(
            child: Container(
              height: 2,
              color: _step >= 1
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          _stepDot(2, 'Edit Plan', _step >= 1),
          Expanded(
            child: Container(
              height: 2,
              color: _step >= 2
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          _stepDot(3, 'Done', _step >= 2),
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
              color:
                  active ? Colors.white : Colors.white.withValues(alpha: 0.3),
            ),
            child: Center(
              child: Text(
                '$n',
                style: TextStyle(
                  color: active
                      ? AppTheme.lightTheme.colorScheme.primary
                      : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  active ? Colors.white : Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  Widget _buildPlanSetup() {
    final byCategory = kClientTagsByCategory;
    final categoryOrder = [
      kTagCatDiet,
      kTagCatGoal,
      kTagCatMedical,
      kTagCatSpecial,
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Plan Title'),
          TextField(
            controller: _titleController,
            decoration:
                _inputDec('e.g. 7-Day Weight Loss Plan for Beginners'),
            onChanged: (v) => _planTitle = v,
          ),
          SizedBox(height: 24),

          GestureDetector(
            onTap: () =>
                setState(() => _showClientList = !_showClientList),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedClientId != null
                      ? AppTheme.lightTheme.colorScheme.primary
                      : Colors.grey.shade300,
                  width: _selectedClientId != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    color: _selectedClientId != null
                        ? AppTheme.lightTheme.colorScheme.primary
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign to a Client (optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _selectedClientId != null
                                ? AppTheme.lightTheme.colorScheme.primary
                                : Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          _selectedClientId != null
                              ? '${_getClientDisplayName(_selectedClientId!)} — tags auto-loaded ✓'
                              : 'Tags will auto-populate from client profile',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_selectedClientId != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.red.shade400,
                      onPressed: () => setState(() {
                        _selectedClientId = null;
                        _selectedClientProfile = null;
                        _selectedTags.clear();
                      }),
                    )
                  else
                    Icon(
                      _showClientList
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
            ),
          ),

          if (_showClientList && _selectedClientId == null) ...[
            SizedBox(height: 8),
            _buildClientListPanel(),
          ],

          SizedBox(height: 24),

          _sectionHeader('Plan Tags'),
          Text(
            _selectedClientId != null
                ? 'Pre-filled from client\'s health profile. Adjust as needed.'
                : 'Select tags. They guide Gemini and help filter plans.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 12),

          ...categoryOrder.map((cat) {
            final tags = byCategory[cat] ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    final selected = _selectedTags.contains(tag.name);
                    return FilterChip(
                      label: Text('${tag.emoji} ${tag.name}'),
                      selected: selected,
                      onSelected: (val) => setState(() {
                        if (val) {
                          _selectedTags.add(tag.name);
                        } else {
                          _selectedTags.remove(tag.name);
                        }
                      }),
                      selectedColor: tag.color.withValues(alpha: 0.15),
                      checkmarkColor: tag.color,
                      labelStyle: TextStyle(
                        color:
                            selected ? tag.color : Colors.grey.shade700,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: selected
                            ? tag.color
                            : Colors.grey.shade300,
                        width: selected ? 1.5 : 1,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
              ],
            );
          }),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getClientDisplayName(String uid) {
    final client = _clients.firstWhere(
      (c) => c['uid'] == uid,
      orElse: () => {},
    );
    if (client.isEmpty) return uid;
    final dn = client['displayName'] as String? ?? '';
    final email = client['email'] as String? ?? '';
    return dn.isNotEmpty ? dn : email.isNotEmpty ? email : uid;
  }

  Widget _buildClientListPanel() {
    if (_loadingClients) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_clients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('No clients found.',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return Container(
      constraints: BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _clients.length,
        itemBuilder: (_, i) {
          final client = _clients[i];
          final uid = client['uid'] as String;
          final displayName = (client['displayName'] as String?) ?? '';
          final email = (client['email'] as String?) ?? '';
          final phone = (client['phone'] as String?) ?? '';
          final profile =
              client['profile'] as Map<String, dynamic>?;
          final clientTags = (client['tags'] as List<String>?) ?? [];
          final label = displayName.isNotEmpty
              ? displayName
              : email.isNotEmpty
                  ? email
                  : phone;
          final sub = profile != null
              ? '${profile['gender'] ?? ''} • ${profile['age'] ?? '?'}y • Goal: ${profile['goal'] ?? 'not set'}'
              : 'No profile yet';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              child: Text(
                label.isNotEmpty ? label[0].toUpperCase() : '?',
                style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                if (clientTags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: clientTags.take(4).map((t) {
                      final tagDef = kClientTagMap[t];
                      final color =
                          tagDef?.color ?? Colors.grey.shade400;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${tagDef?.emoji ?? ''} $t',
                          style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            isThreeLine: clientTags.isNotEmpty,
            onTap: () => _selectClient(uid, profile),
          );
        },
      ),
    );
  }

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
            SizedBox(height: 24),
            Text('Gemini is creating the plan...',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey.shade700)),
            SizedBox(height: 8),
            Text(
              _selectedClientProfile != null
                  ? 'Personalising for client profile and tags'
                  : 'Crafting a plan based on selected tags',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Plan Details'),

          if (_selectedTags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedTags.map((tagName) {
                final tagDef = kClientTagMap[tagName];
                final color = tagDef?.color ?? Colors.grey.shade600;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${tagDef?.emoji ?? ''} $tagName',
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 12),
          ],

          TextField(
            controller: _titleController,
            decoration: _inputDec('Plan Title'),
            onChanged: (v) => _planTitle = v,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: _inputDec('Notes for client (optional)'),
            onChanged: (v) => _planNotes = v,
          ),
          SizedBox(height: 24),

          _sectionHeader('7-Day Meal Plan'),
          SizedBox(height: 8),

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
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF1a1a1a)),
        ),
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
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  Widget _buildSuccess() => Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade500, size: 52),
              ),
              SizedBox(height: 24),
              const Text('Plan Saved! 🎉',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                _selectedClientId != null
                    ? 'The diet plan has been saved and assigned to the client. They can view it in the My Diet Plan section.'
                    : 'The diet plan has been saved to your library. You can assign it to a client anytime.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _step = 0;
                    _selectedClientId = null;
                    _selectedClientProfile = null;
                    _selectedTags.clear();
                    _weekPlan = [];
                    _titleController.clear();
                    _notesController.clear();
                    _showClientList = false;
                  });
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Another Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Diet Plans',
                    style: TextStyle(
                        color:
                            AppTheme.lightTheme.colorScheme.primary)),
              ),
            ],
          ),
        ),
      );

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: _step == 0
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generating ? null : _generateWithGemini,
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(
                  _generating
                      ? 'Generating...'
                      : _selectedClientId != null
                          ? 'Generate Personalised Plan'
                          : 'Generate Plan with AI',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
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
                        vertical: 14, horizontal: 16),
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
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_weekPlan.isNotEmpty && !_saving)
                        ? _savePlan
                        : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Plan',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
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
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF61b239),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(
                        top: Radius.circular(16))
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
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
              padding: EdgeInsets.all(16),
              child: Column(
                children: allMeals.entries
                    .map((entry) => _MealSection(
                          mealName: entry.key,
                          items: entry.value,
                          color:
                              _mealColors[entry.key] ?? Colors.grey,
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
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 8),
              Text(mealName,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: color)),
            ],
          ),
          SizedBox(height: 8),
          ...items.map((item) => _EditableItem(
                item: item,
                accentColor: color,
                onChanged: onChanged,
              )),
          GestureDetector(
            onTap: () {
              items.add(MealEntry());
              onChanged();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 16, color: color.withValues(alpha: 0.6)),
                  SizedBox(width: 4),
                  Text('Add item',
                      style: TextStyle(
                          color: color.withValues(alpha: 0.6),
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
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
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
          SizedBox(width: 8),
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
          SizedBox(width: 8),
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

class _PlanPickerPopup extends StatefulWidget {
  @override
  State<_PlanPickerPopup> createState() => _PlanPickerPopupState();
}

class _PlanPickerPopupState extends State<_PlanPickerPopup> {
  bool _loading = true;
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      // Fetch plans that are structured and not necessarily assigned to anyone yet (template plans)
      final snap = await FirebaseService.instance.plans
          .where('format', isEqualTo: 'structured')
          .orderBy('uploadedAt', descending: true)
          .limit(20)
          .get();
      
      if (mounted) {
        setState(() {
          _plans = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Load Existing Plan'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _plans.isEmpty
                ? const Center(child: Text('No plans found in library.'))
                : ListView.builder(
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return ListTile(
                        title: Text(plan['title'] ?? 'Untitled Plan'),
                        subtitle: Text(plan['notes'] ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => Navigator.pop(context, plan),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}
