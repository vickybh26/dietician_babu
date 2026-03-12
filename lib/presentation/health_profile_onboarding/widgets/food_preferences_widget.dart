import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FoodPreferencesWidget extends StatelessWidget {
  final List<String> selectedCuisines;
  final List<String> selectedDietaryRestrictions;
  final Function(List<String>) onCuisinesChanged;
  final Function(List<String>) onDietaryRestrictionsChanged;

  const FoodPreferencesWidget({
    Key? key,
    required this.selectedCuisines,
    required this.selectedDietaryRestrictions,
    required this.onCuisinesChanged,
    required this.onDietaryRestrictionsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cuisines = [
      {
        'id': 'indian',
        'title': 'Indian',
        'icon': 'restaurant',
        'color': AppTheme.lightTheme.colorScheme.secondary,
      },
      {
        'id': 'continental',
        'title': 'Continental',
        'icon': 'local_dining',
        'color': AppTheme.lightTheme.colorScheme.primary,
      },
      {
        'id': 'chinese',
        'title': 'Chinese',
        'icon': 'ramen_dining',
        'color': AppTheme.lightTheme.colorScheme.tertiary,
      },
      {
        'id': 'mediterranean',
        'title': 'Mediterranean',
        'icon': 'set_meal',
        'color': AppTheme.lightTheme.colorScheme.error,
      },
      {
        'id': 'mexican',
        'title': 'Mexican',
        'icon': 'local_pizza',
        'color': Colors.orange,
      },
      {
        'id': 'thai',
        'title': 'Thai',
        'icon': 'rice_bowl',
        'color': Colors.purple,
      },
    ];

    final List<Map<String, dynamic>> dietaryRestrictions = [
      {
        'id': 'vegetarian',
        'title': 'Vegetarian',
        'description': 'No meat, fish, or poultry',
        'icon': 'eco',
        'color': AppTheme.lightTheme.colorScheme.secondary,
      },
      {
        'id': 'vegan',
        'title': 'Vegan',
        'description': 'No animal products',
        'icon': 'nature',
        'color': AppTheme.lightTheme.colorScheme.tertiary,
      },
      {
        'id': 'gluten_free',
        'title': 'Gluten-Free',
        'description': 'No wheat, barley, or rye',
        'icon': 'no_food',
        'color': Colors.orange,
      },
      {
        'id': 'dairy_free',
        'title': 'Dairy-Free',
        'description': 'No milk or dairy products',
        'icon': 'block',
        'color': Colors.red,
      },
      {
        'id': 'keto',
        'title': 'Keto',
        'description': 'Low carb, high fat',
        'icon': 'fitness_center',
        'color': AppTheme.lightTheme.colorScheme.primary,
      },
      {
        'id': 'paleo',
        'title': 'Paleo',
        'description': 'Whole foods, no processed',
        'icon': 'outdoor_grill',
        'color': Colors.brown,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are your food preferences?',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Help us recommend meals you\'ll love',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4.h),
        _buildSectionHeader('Favorite Cuisines', 'Select all that apply'),
        SizedBox(height: 2.h),
        _buildCuisineGrid(cuisines),
        SizedBox(height: 4.h),
        _buildSectionHeader(
            'Dietary Restrictions', 'Any special dietary needs?'),
        SizedBox(height: 2.h),
        ...dietaryRestrictions
            .map((restriction) => _buildDietaryRestrictionCard(restriction))
            .toList(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          subtitle,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCuisineGrid(List<Map<String, dynamic>> cuisines) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 2.5,
      ),
      itemCount: cuisines.length,
      itemBuilder: (context, index) {
        final cuisine = cuisines[index];
        final bool isSelected = selectedCuisines.contains(cuisine['id']);

        return InkWell(
          onTap: () => _toggleCuisine(cuisine['id']),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? (cuisine['color'] as Color).withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? cuisine['color'] as Color
                    : AppTheme.lightTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: (cuisine['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: cuisine['icon'],
                    color: cuisine['color'] as Color,
                    size: 5.w,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    cuisine['title'],
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? cuisine['color'] as Color
                          : AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: cuisine['color'] as Color,
                    size: 4.w,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDietaryRestrictionCard(Map<String, dynamic> restriction) {
    final bool isSelected =
        selectedDietaryRestrictions.contains(restriction['id']);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _toggleDietaryRestriction(restriction['id']),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isSelected
                ? (restriction['color'] as Color).withValues(alpha: 0.1)
                : AppTheme.lightTheme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? restriction['color'] as Color
                  : AppTheme.lightTheme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: (restriction['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: restriction['icon'],
                  color: restriction['color'] as Color,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restriction['title'],
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? restriction['color'] as Color
                            : AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      restriction['description'],
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: restriction['color'] as Color,
                  size: 6.w,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleCuisine(String cuisineId) {
    List<String> updatedCuisines = List.from(selectedCuisines);

    if (updatedCuisines.contains(cuisineId)) {
      updatedCuisines.remove(cuisineId);
    } else {
      updatedCuisines.add(cuisineId);
    }

    onCuisinesChanged(updatedCuisines);
  }

  void _toggleDietaryRestriction(String restrictionId) {
    List<String> updatedRestrictions = List.from(selectedDietaryRestrictions);

    if (updatedRestrictions.contains(restrictionId)) {
      updatedRestrictions.remove(restrictionId);
    } else {
      updatedRestrictions.add(restrictionId);
    }

    onDietaryRestrictionsChanged(updatedRestrictions);
  }
}
