import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class DietPlanViewer extends StatefulWidget {
  /// When [isEmbedded] is true the widget renders only the body content
  /// (plan list or empty state) without its own Scaffold/AppBar. Use this
  /// when embedding inside another Scaffold, e.g. as the Meals tab in
  /// DashboardHome.
  final bool isEmbedded;
  const DietPlanViewer({Key? key, this.isEmbedded = false}) : super(key: key);
  @override
  State<DietPlanViewer> createState() => _DietPlanViewerState();
}

class _DietPlanViewerState extends State<DietPlanViewer> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) {
      if (widget.isEmbedded) {
        return const Center(child: Text('Not logged in'));
      }
      return Scaffold(
        appBar: _appBar(),
        body: const Center(child: Text('Not logged in')),
      );
    }

    final bodyContent = StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.instance.plans
          .where('clientId', isEqualTo: uid)
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading plans: ${snapshot.error}',
                style: TextStyle(color: Colors.red.shade400)),
          );
        }

        final plans = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] != 'archived';
        }).toList();

        if (plans.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: EdgeInsets.all(4.w),
          itemCount: plans.length,
          separatorBuilder: (_, __) => SizedBox(height: 2.h),
          itemBuilder: (context, index) {
            final plan = plans[index].data() as Map<String, dynamic>;
            final isStructured = plan['format'] == 'structured';
            return isStructured
                ? _StructuredPlanCard(plan: plan)
                : _PlanCard(plan: plan);
          },
        );
      },
    );

    // If embedded (used as a tab inside DashboardHome) skip the Scaffold wrapper.
    if (widget.isEmbedded) return bodyContent;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _appBar(),
      body: bodyContent,
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: const Text('My Diet Plans'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.description_outlined,
                    size: 44,
                    color: AppTheme.lightTheme.colorScheme.primary),
              ),
              SizedBox(height: 3.h),
              Text(
                'No Diet Plans Yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900),
              ),
              SizedBox(height: 1.h),
              Text(
                'Your dietician will upload your personalised plan here. Check back soon!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final title = plan['title'] as String? ?? 'Diet Plan';
    final notes = plan['notes'] as String? ?? '';
    final fileUrl = plan['fileUrl'] as String? ?? '';
    final type = plan['type'] as String? ?? 'Regular';
    final uploadedAt = plan['uploadedAt'] as Timestamp?;

    String dateStr = '';
    if (uploadedAt != null) {
      final d = uploadedAt.toDate();
      dateStr = '${d.day}/${d.month}/${d.year}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Diet Plan',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateStr.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.grey.shade500),
                      SizedBox(width: 1.w),
                      Text(
                        'Uploaded on $dateStr',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                ],
                if (notes.isNotEmpty) ...[
                  Text(
                    notes,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.5.h),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: fileUrl.isNotEmpty
                        ? () => _openPdf(context, fileUrl)
                        : null,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('View Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the plan file')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

// ─── Structured plan card ────────────────────────────────────────────────────

class _StructuredPlanCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  const _StructuredPlanCard({required this.plan});

  @override
  State<_StructuredPlanCard> createState() => _StructuredPlanCardState();
}

class _StructuredPlanCardState extends State<_StructuredPlanCard> {
  int _selectedDay = 0;

  static const _mealIcons = {
    'breakfast': '🌅',
    'midMorning': '🍎',
    'lunch': '🍱',
    'eveningSnack': '☕',
    'dinner': '🌙',
  };
  static const _mealLabels = {
    'breakfast': 'Breakfast',
    'midMorning': 'Mid-Morning',
    'lunch': 'Lunch',
    'eveningSnack': 'Evening Snack',
    'dinner': 'Dinner',
  };
  static const _mealColors = {
    'breakfast': Color(0xFF4CAF50),
    'midMorning': Color(0xFF2196F3),
    'lunch': Color(0xFFFF9800),
    'eveningSnack': Color(0xFF9C27B0),
    'dinner': Color(0xFFF44336),
  };

  @override
  Widget build(BuildContext context) {
    final title = widget.plan['title'] as String? ?? 'Diet Plan';
    final notes = widget.plan['notes'] as String? ?? '';
    final uploadedAt = widget.plan['uploadedAt'] as Timestamp?;
    final days = (widget.plan['weekPlan'] as List?) ?? [];

    String dateStr = '';
    if (uploadedAt != null) {
      final d = uploadedAt.toDate();
      dateStr = '${d.day}/${d.month}/${d.year}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF61b239), Color(0xFF4a9a2a)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu_rounded,
                    color: Colors.white, size: 22),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      if (dateStr.isNotEmpty)
                        Text('Created $dateStr',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (notes.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF61b239).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Color(0xFF61b239)),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(notes,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF61b239))),
                    ),
                  ],
                ),
              ),
            ),

          // Day selector
          if (days.isNotEmpty) ...[
            SizedBox(height: 1.5.h),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isSelected = _selectedDay == i;
                  final dayLabel =
                      (days[i] as Map<String, dynamic>)['day'] as String? ??
                          'Day ${i + 1}';
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF61b239)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dayLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 1.5.h),

            // Selected day meals
            if (_selectedDay < days.length)
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 3.h),
                child: _buildDayMeals(
                    days[_selectedDay] as Map<String, dynamic>),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayMeals(Map<String, dynamic> day) {
    final mealKeys = [
      'breakfast',
      'midMorning',
      'lunch',
      'eveningSnack',
      'dinner'
    ];

    return Column(
      children: mealKeys.map((key) {
        final items = (day[key] as List?) ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        final color = _mealColors[key] ?? Colors.grey;
        final label = _mealLabels[key] ?? key;
        final icon = _mealIcons[key] ?? '🍽';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: color)),
                  ],
                ),
              ),
              ...items.map((item) {
                final m = item as Map<String, dynamic>;
                return Padding(
                  padding:
                      const EdgeInsets.fromLTRB(12, 2, 12, 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          m['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          m['quantity'] ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${m['calories']} kcal',
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
