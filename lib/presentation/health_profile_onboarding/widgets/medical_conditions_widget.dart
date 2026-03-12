import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MedicalConditionsWidget extends StatefulWidget {
  final List<String> selectedConditions;
  final Function(List<String>) onConditionsChanged;

  const MedicalConditionsWidget({
    Key? key,
    required this.selectedConditions,
    required this.onConditionsChanged,
  }) : super(key: key);

  @override
  State<MedicalConditionsWidget> createState() =>
      _MedicalConditionsWidgetState();
}

class _MedicalConditionsWidgetState extends State<MedicalConditionsWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allConditions = [
    {
      'id': 'diabetes',
      'title': 'Diabetes',
      'icon': 'bloodtype',
      'category': 'common',
    },
    {
      'id': 'hypertension',
      'title': 'High Blood Pressure',
      'icon': 'favorite',
      'category': 'common',
    },
    {
      'id': 'heart_disease',
      'title': 'Heart Disease',
      'icon': 'monitor_heart',
      'category': 'common',
    },
    {
      'id': 'thyroid',
      'title': 'Thyroid Disorder',
      'icon': 'medical_services',
      'category': 'common',
    },
    {
      'id': 'pcos',
      'title': 'PCOS/PCOD',
      'icon': 'health_and_safety',
      'category': 'common',
    },
    {
      'id': 'cholesterol',
      'title': 'High Cholesterol',
      'icon': 'water_drop',
      'category': 'common',
    },
    {
      'id': 'arthritis',
      'title': 'Arthritis',
      'icon': 'accessibility',
      'category': 'other',
    },
    {
      'id': 'asthma',
      'title': 'Asthma',
      'icon': 'air',
      'category': 'other',
    },
    {
      'id': 'kidney_disease',
      'title': 'Kidney Disease',
      'icon': 'medical_information',
      'category': 'other',
    },
    {
      'id': 'liver_disease',
      'title': 'Liver Disease',
      'icon': 'local_hospital',
      'category': 'other',
    },
    {
      'id': 'depression',
      'title': 'Depression/Anxiety',
      'icon': 'psychology',
      'category': 'other',
    },
    {
      'id': 'none',
      'title': 'None of the above',
      'icon': 'check_circle',
      'category': 'none',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredConditions = _allConditions.where((condition) {
      return condition['title']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    final commonConditions =
        filteredConditions.where((c) => c['category'] == 'common').toList();
    final otherConditions =
        filteredConditions.where((c) => c['category'] == 'other').toList();
    final noneCondition =
        filteredConditions.where((c) => c['category'] == 'none').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you have any medical conditions?',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'This helps us create a safe and effective diet plan for you',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 3.h),
        _buildSearchField(),
        SizedBox(height: 3.h),
        if (commonConditions.isNotEmpty) ...[
          _buildSectionHeader('Common Conditions'),
          SizedBox(height: 2.h),
          ...commonConditions
              .map((condition) => _buildConditionCard(condition))
              .toList(),
          SizedBox(height: 3.h),
        ],
        if (otherConditions.isNotEmpty) ...[
          _buildSectionHeader('Other Conditions'),
          SizedBox(height: 2.h),
          ...otherConditions
              .map((condition) => _buildConditionCard(condition))
              .toList(),
          SizedBox(height: 3.h),
        ],
        if (noneCondition.isNotEmpty) ...[
          ...noneCondition
              .map((condition) => _buildConditionCard(condition))
              .toList(),
        ],
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.dividerColor,
        ),
      ),
      child: TextFormField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search medical conditions...',
          prefixIcon: Padding(
            padding: EdgeInsets.all(3.w),
            child: CustomIconWidget(
              iconName: 'search',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: CustomIconWidget(
                    iconName: 'clear',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.lightTheme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildConditionCard(Map<String, dynamic> condition) {
    final bool isSelected = widget.selectedConditions.contains(condition['id']);
    final bool isNoneOption = condition['id'] == 'none';

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: InkWell(
        onTap: () => _toggleCondition(condition['id']),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isSelected
                ? (isNoneOption
                    ? AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.1)
                    : AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1))
                : AppTheme.lightTheme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? (isNoneOption
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.primary)
                  : AppTheme.lightTheme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isNoneOption
                          ? AppTheme.lightTheme.colorScheme.tertiary
                              .withValues(alpha: 0.1)
                          : AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.1))
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomIconWidget(
                  iconName: condition['icon'],
                  color: isSelected
                      ? (isNoneOption
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.primary)
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  condition['title'],
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? (isNoneOption
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.primary)
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: isNoneOption
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.primary,
                  size: 5.w,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleCondition(String conditionId) {
    List<String> updatedConditions = List.from(widget.selectedConditions);

    if (conditionId == 'none') {
      // If "None" is selected, clear all other conditions
      if (updatedConditions.contains('none')) {
        updatedConditions.remove('none');
      } else {
        updatedConditions = ['none'];
      }
    } else {
      // If any other condition is selected, remove "None" if it exists
      if (updatedConditions.contains('none')) {
        updatedConditions.remove('none');
      }

      if (updatedConditions.contains(conditionId)) {
        updatedConditions.remove(conditionId);
      } else {
        updatedConditions.add(conditionId);
      }
    }

    widget.onConditionsChanged(updatedConditions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
