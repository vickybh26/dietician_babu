import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SummaryWidget extends StatelessWidget {
  final Map<String, dynamic> profileData;
  final Function(String) onEditSection;

  const SummaryWidget({
    Key? key,
    required this.profileData,
    required this.onEditSection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: 'celebration',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 8.w,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Great! You\'re all set',
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Review your profile before we create your personalized plan',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        _buildSummaryCard(
          'Basic Information',
          'basic_info',
          [
            'Gender: ${_formatGender(profileData['gender'] ?? '')}',
            'Age: ${profileData['age'] ?? 0} years',
            'Height: ${profileData['height']?.toStringAsFixed(0) ?? '0'} cm',
            'Weight: ${profileData['weight']?.toStringAsFixed(1) ?? '0'} kg',
          ],
          'person',
        ),
        _buildSummaryCard(
          'Health Goal',
          'goal',
          [
            _formatGoal(profileData['goal'] ?? ''),
          ],
          'flag',
        ),
        _buildSummaryCard(
          'Activity Level',
          'activity',
          [
            _formatActivityLevel(profileData['activityLevel'] ?? 1.0),
          ],
          'directions_run',
        ),
        if ((profileData['medicalConditions'] as List<String>?)?.isNotEmpty ==
            true)
          _buildSummaryCard(
            'Medical Conditions',
            'medical',
            (profileData['medicalConditions'] as List<String>)
                .map((condition) => _formatMedicalCondition(condition))
                .toList(),
            'medical_services',
          ),
        if ((profileData['cuisines'] as List<String>?)?.isNotEmpty == true ||
            (profileData['dietaryRestrictions'] as List<String>?)?.isNotEmpty ==
                true)
          _buildSummaryCard(
            'Food Preferences',
            'food',
            [
              if ((profileData['cuisines'] as List<String>?)?.isNotEmpty ==
                  true)
                'Cuisines: ${(profileData['cuisines'] as List<String>).map((c) => _formatCuisine(c)).join(', ')}',
              if ((profileData['dietaryRestrictions'] as List<String>?)
                      ?.isNotEmpty ==
                  true)
                'Dietary: ${(profileData['dietaryRestrictions'] as List<String>).map((d) => _formatDietaryRestriction(d)).join(', ')}',
            ],
            'restaurant_menu',
          ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String sectionKey,
    List<String> items,
    String icon,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: icon,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => onEditSection(sectionKey),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'edit',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Edit',
                        style:
                            AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...items
              .map((item) => Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 0.5.h),
                          width: 1.w,
                          height: 1.w,
                          decoration: BoxDecoration(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            borderRadius: BorderRadius.circular(0.5.w),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            item,
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  String _formatGender(String gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return 'Not specified';
    }
  }

  String _formatGoal(String goal) {
    switch (goal) {
      case 'weight_loss':
        return 'Weight Loss - Lose weight in a healthy and sustainable way';
      case 'muscle_gain':
        return 'Muscle Gain - Build lean muscle mass and strength';
      case 'maintenance':
        return 'Maintenance - Maintain current weight and improve health';
      case 'general_health':
        return 'General Health - Improve overall health and wellness';
      default:
        return 'Not specified';
    }
  }

  String _formatActivityLevel(double level) {
    switch (level.round()) {
      case 1:
        return 'Sedentary - Little to no exercise';
      case 2:
        return 'Lightly Active - Light exercise 1-3 days/week';
      case 3:
        return 'Moderately Active - Moderate exercise 3-5 days/week';
      case 4:
        return 'Very Active - Hard exercise 6-7 days/week';
      case 5:
        return 'Extremely Active - Very hard exercise, physical job';
      default:
        return 'Not specified';
    }
  }

  String _formatMedicalCondition(String condition) {
    switch (condition) {
      case 'diabetes':
        return 'Diabetes';
      case 'hypertension':
        return 'High Blood Pressure';
      case 'heart_disease':
        return 'Heart Disease';
      case 'thyroid':
        return 'Thyroid Disorder';
      case 'pcos':
        return 'PCOS/PCOD';
      case 'cholesterol':
        return 'High Cholesterol';
      case 'arthritis':
        return 'Arthritis';
      case 'asthma':
        return 'Asthma';
      case 'kidney_disease':
        return 'Kidney Disease';
      case 'liver_disease':
        return 'Liver Disease';
      case 'depression':
        return 'Depression/Anxiety';
      case 'none':
        return 'None of the above';
      default:
        return condition;
    }
  }

  String _formatCuisine(String cuisine) {
    switch (cuisine) {
      case 'indian':
        return 'Indian';
      case 'continental':
        return 'Continental';
      case 'chinese':
        return 'Chinese';
      case 'mediterranean':
        return 'Mediterranean';
      case 'mexican':
        return 'Mexican';
      case 'thai':
        return 'Thai';
      default:
        return cuisine;
    }
  }

  String _formatDietaryRestriction(String restriction) {
    switch (restriction) {
      case 'vegetarian':
        return 'Vegetarian';
      case 'vegan':
        return 'Vegan';
      case 'gluten_free':
        return 'Gluten-Free';
      case 'dairy_free':
        return 'Dairy-Free';
      case 'keto':
        return 'Keto';
      case 'paleo':
        return 'Paleo';
      default:
        return restriction;
    }
  }
}
