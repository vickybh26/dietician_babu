import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../../core/client_tags.dart';

/// Step 6 of onboarding — lets the client review auto-suggested tags
/// and add/remove any tags from the full canonical list.
///
/// Tags are saved to Firestore: clients/{uid}.tags  →  List<String>
class ClientTagsWidget extends StatelessWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;

  const ClientTagsWidget({
    Key? key,
    required this.selectedTags,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final byCategory = kClientTagsByCategory;
    final categoryOrder = [
      kTagCatDiet,
      kTagCatGoal,
      kTagCatMedical,
      kTagCatSpecial,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Health Tags',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.8.h),
        Text(
          'We\'ve pre-selected tags based on your answers. Tap to add or remove.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),

        // Auto-suggested banner
        if (selectedTags.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.lightTheme.colorScheme.primary, size: 16),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    '${selectedTags.length} tag${selectedTags.length == 1 ? '' : 's'} auto-detected from your profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 3.h),

        // Categories
        ...categoryOrder.map((category) {
          final tags = byCategory[category] ?? [];
          return _CategorySection(
            category: category,
            tags: tags,
            selectedTags: selectedTags,
            onToggle: _toggleTag,
          );
        }),
      ],
    );
  }

  void _toggleTag(String tagName) {
    final updated = List<String>.from(selectedTags);
    if (updated.contains(tagName)) {
      updated.remove(tagName);
    } else {
      updated.add(tagName);
    }
    onTagsChanged(updated);
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<ClientTag> tags;
  final List<String> selectedTags;
  final void Function(String) onToggle;

  const _CategorySection({
    required this.category,
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final selected = selectedTags.contains(tag.name);
            return GestureDetector(
              onTap: () => onToggle(tag.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? tag.color.withValues(alpha: 0.12)
                      : AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? tag.color
                        : AppTheme.lightTheme.dividerColor,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tag.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? tag.color
                            : AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check_circle_rounded,
                          color: tag.color, size: 14),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 3.h),
      ],
    );
  }
}
