import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AchievementBadgeWidget extends StatefulWidget {
  final String title;
  final String description;
  final String iconName;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const AchievementBadgeWidget({
    Key? key,
    required this.title,
    required this.description,
    required this.iconName,
    required this.isUnlocked,
    this.onTap,
  }) : super(key: key);

  @override
  State<AchievementBadgeWidget> createState() => _AchievementBadgeWidgetState();
}

class _AchievementBadgeWidgetState extends State<AchievementBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isUnlocked) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 20.w,
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: widget.isUnlocked
              ? AppTheme.lightTheme.colorScheme.surface
              : AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(
            color: widget.isUnlocked
                ? AppTheme.successLight
                : AppTheme.dividerLight,
            width: widget.isUnlocked ? 2 : 1,
          ),
          boxShadow: widget.isUnlocked
              ? [
                  BoxShadow(
                    color: AppTheme.successLight.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isUnlocked ? _scaleAnimation.value : 1.0,
                  child: Transform.rotate(
                    angle: widget.isUnlocked
                        ? _rotationAnimation.value * 0.1
                        : 0.0,
                    child: Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: widget.isUnlocked
                            ? AppTheme.successLight.withValues(alpha: 0.1)
                            : AppTheme.dividerLight.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: widget.iconName,
                          color: widget.isUnlocked
                              ? AppTheme.successLight
                              : AppTheme.textDisabledLight,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 1.h),
            Text(
              widget.title,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: widget.isUnlocked
                    ? AppTheme.textPrimaryLight
                    : AppTheme.textDisabledLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
