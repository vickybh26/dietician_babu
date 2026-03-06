import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class DietPlanViewer extends StatefulWidget {
  const DietPlanViewer({Key? key}) : super(key: key);
  @override
  State<DietPlanViewer> createState() => _DietPlanViewerState();
}

class _DietPlanViewerState extends State<DietPlanViewer> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _appBar(),
      body: StreamBuilder<QuerySnapshot>(
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

          final plans = snapshot.data?.docs ?? [];

          if (plans.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: plans.length,
            separatorBuilder: (_, __) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final plan = plans[index].data() as Map<String, dynamic>;
              return _PlanCard(plan: plan);
            },
          );
        },
      ),
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
                  child: Text(
                    type,
                    style: const TextStyle(
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
