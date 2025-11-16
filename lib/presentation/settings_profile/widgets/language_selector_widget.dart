import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LanguageSelectorWidget extends StatefulWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelectorWidget({
    Key? key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  late String selectedLanguage;

  final List<LanguageOption> languages = [
    LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageOption(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
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
        children: languages.asMap().entries.map((entry) {
          final index = entry.key;
          final language = entry.value;
          final isLast = index == languages.length - 1;

          return Column(
            children: [
              _buildLanguageOption(language),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppTheme.lightTheme.dividerColor,
                  indent: 4.w,
                  endIndent: 4.w,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageOption(LanguageOption language) {
    final isSelected = selectedLanguage == language.code;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      leading: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(2.w),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            language.flag,
            style: TextStyle(fontSize: 20.sp),
          ),
        ),
      ),
      title: Text(
        language.name,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: isSelected ? AppTheme.lightTheme.primaryColor : null,
        ),
      ),
      subtitle: Text(
        language.nativeName,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.primaryColor,
              size: 24,
            )
          : CustomIconWidget(
              iconName: 'radio_button_unchecked',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
      onTap: () {
        setState(() {
          selectedLanguage = language.code;
        });
        widget.onLanguageChanged(language.code);

        // Show confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to ${language.name}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}

class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}
