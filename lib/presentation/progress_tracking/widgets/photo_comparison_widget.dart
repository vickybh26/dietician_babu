import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhotoComparisonWidget extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final VoidCallback onAddPhoto;

  const PhotoComparisonWidget({
    Key? key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    required this.onAddPhoto,
  }) : super(key: key);

  @override
  State<PhotoComparisonWidget> createState() => _PhotoComparisonWidgetState();
}

class _PhotoComparisonWidgetState extends State<PhotoComparisonWidget> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Photos',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              GestureDetector(
                onTap: widget.onAddPhoto,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'add_a_photo',
                        color: AppTheme.primaryLight,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Add Photo',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryLight,
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
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2.w),
              child: Stack(
                children: [
                  // Before image (full width)
                  Positioned.fill(
                    child: CustomImageWidget(
                      imageUrl: widget.beforeImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // After image (clipped by slider)
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _SliderClipper(_sliderValue),
                      child: CustomImageWidget(
                        imageUrl: widget.afterImageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Slider line
                  Positioned(
                    left: _sliderValue * (100.w - 8.w) - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: AppTheme.onPrimaryLight,
                    ),
                  ),
                  // Slider handle
                  Positioned(
                    left: _sliderValue * (100.w - 8.w) - 3.w,
                    top: 50.w - 3.w,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _sliderValue =
                              (details.localPosition.dx / (100.w - 8.w))
                                  .clamp(0.0, 1.0);
                        });
                      },
                      child: Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: AppTheme.onPrimaryLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: 'drag_indicator',
                            color: AppTheme.primaryLight,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Before',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'After',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double sliderValue;

  _SliderClipper(this.sliderValue);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      sliderValue * size.width,
      0,
      size.width,
      size.height,
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
