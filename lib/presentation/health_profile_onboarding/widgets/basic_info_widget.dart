import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BasicInfoWidget extends StatelessWidget {
  final int age;
  final double height;
  final double weight;
  final String gender;
  final Function(int) onAgeChanged;
  final Function(double) onHeightChanged;
  final Function(double) onWeightChanged;
  final Function(String) onGenderChanged;

  const BasicInfoWidget({
    Key? key,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    required this.onAgeChanged,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onGenderChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'This information helps us calculate your nutritional needs',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4.h),
        _buildGenderSelection(),
        SizedBox(height: 3.h),
        _buildNumberInput(
          label: 'Age',
          value: age.toString(),
          suffix: 'years',
          icon: 'cake',
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null && intValue > 0 && intValue <= 120) {
              onAgeChanged(intValue);
            }
          },
        ),
        SizedBox(height: 2.h),
        _buildNumberInput(
          label: 'Height',
          value: height.toStringAsFixed(0),
          suffix: 'cm',
          icon: 'height',
          onChanged: (value) {
            final doubleValue = double.tryParse(value);
            if (doubleValue != null && doubleValue > 0 && doubleValue <= 300) {
              onHeightChanged(doubleValue);
            }
          },
        ),
        SizedBox(height: 2.h),
        _buildNumberInput(
          label: 'Weight',
          value: weight.toStringAsFixed(1),
          suffix: 'kg',
          icon: 'monitor_weight',
          onChanged: (value) {
            final doubleValue = double.tryParse(value);
            if (doubleValue != null && doubleValue > 0 && doubleValue <= 500) {
              onWeightChanged(doubleValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    final List<Map<String, dynamic>> genders = [
      {
        'id': 'male',
        'title': 'Male',
        'icon': 'male',
      },
      {
        'id': 'female',
        'title': 'Female',
        'icon': 'female',
      },
      {
        'id': 'other',
        'title': 'Other',
        'icon': 'person',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: genders.map((genderOption) {
            final bool isSelected = gender == genderOption['id'];
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                    right: genderOption['id'] != 'other' ? 2.w : 0),
                child: InkWell(
                  onTap: () => onGenderChanged(genderOption['id']),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.1)
                          : AppTheme.lightTheme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: genderOption['icon'],
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 6.w,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          genderOption['title'],
                          style: AppTheme.lightTheme.textTheme.labelMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required String value,
    required String suffix,
    required String icon,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor,
            ),
          ),
          child: TextFormField(
            initialValue: value,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: icon,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 5.w,
                ),
              ),
              suffixText: suffix,
              suffixStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            ),
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
