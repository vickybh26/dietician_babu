import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_export.dart';
import '../../core/client_tags.dart';
import '../../routes/app_routes.dart';
import '../../services/firebase_service.dart';
import './widgets/activity_level_widget.dart';
import './widgets/basic_info_widget.dart';
import './widgets/client_tags_widget.dart';
import './widgets/food_preferences_widget.dart';
import './widgets/goal_selection_widget.dart';
import './widgets/medical_conditions_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/summary_widget.dart';

class HealthProfileOnboarding extends StatefulWidget {
  const HealthProfileOnboarding({Key? key}) : super(key: key);

  @override
  State<HealthProfileOnboarding> createState() =>
      _HealthProfileOnboardingState();
}

class _HealthProfileOnboardingState extends State<HealthProfileOnboarding> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7; // added tags step

  // Profile data
  String _selectedGoal = '';
  double _activityLevel = 1.0;
  int _age = 25;
  double _height = 170.0;
  double _weight = 70.0;
  String _gender = '';
  List<String> _selectedMedicalConditions = [];
  List<String> _selectedCuisines = [];
  List<String> _selectedDietaryRestrictions = [];
  List<String> _selectedTags = []; // NEW: client-facing health tags

  final List<String> _stepTitles = [
    'What\'s your primary goal?',
    'How active are you?',
    'Tell us about yourself',
    'Any medical conditions?',
    'Food preferences',
    'Your health tags',
    'Review your profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ProgressIndicatorWidget(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              stepTitles: _stepTitles,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                    if (index == 5) _autoDeriveTags();
                  });
                },
                children: [
                  _buildStepContent(_buildGoalSelectionStep()),
                  _buildStepContent(_buildActivityLevelStep()),
                  _buildStepContent(_buildBasicInfoStep()),
                  _buildStepContent(_buildMedicalConditionsStep()),
                  _buildStepContent(_buildFoodPreferencesStep()),
                  _buildStepContent(_buildTagsStep()),
                  _buildStepContent(_buildSummaryStep()),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  void _autoDeriveTags() {
    final derived = deriveTags(
      goal: _selectedGoal,
      dietaryRestrictions: _selectedDietaryRestrictions,
      medicalConditions: _selectedMedicalConditions,
    );
    final merged = <String>{..._selectedTags, ...derived};
    setState(() => _selectedTags = merged.toList());
  }

  Widget _buildStepContent(Widget content) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: content,
    );
  }

  Widget _buildGoalSelectionStep() {
    return GoalSelectionWidget(
      selectedGoal: _selectedGoal,
      onGoalSelected: (goal) {
        setState(() => _selectedGoal = goal);
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildActivityLevelStep() {
    return ActivityLevelWidget(
      activityLevel: _activityLevel,
      onActivityLevelChanged: (level) {
        setState(() => _activityLevel = level);
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildBasicInfoStep() {
    return BasicInfoWidget(
      age: _age,
      height: _height,
      weight: _weight,
      gender: _gender,
      onAgeChanged: (age) => setState(() => _age = age),
      onHeightChanged: (height) => setState(() => _height = height),
      onWeightChanged: (weight) => setState(() => _weight = weight),
      onGenderChanged: (gender) {
        setState(() => _gender = gender);
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildMedicalConditionsStep() {
    return MedicalConditionsWidget(
      selectedConditions: _selectedMedicalConditions,
      onConditionsChanged: (conditions) {
        setState(() => _selectedMedicalConditions = conditions);
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildFoodPreferencesStep() {
    return FoodPreferencesWidget(
      selectedCuisines: _selectedCuisines,
      selectedDietaryRestrictions: _selectedDietaryRestrictions,
      onCuisinesChanged: (cuisines) {
        setState(() => _selectedCuisines = cuisines);
        HapticFeedback.lightImpact();
      },
      onDietaryRestrictionsChanged: (restrictions) {
        setState(() => _selectedDietaryRestrictions = restrictions);
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildTagsStep() {
    return ClientTagsWidget(
      selectedTags: _selectedTags,
      onTagsChanged: (tags) {
        setState(() => _selectedTags = tags);
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildSummaryStep() {
    final profileData = {
      'goal': _selectedGoal,
      'activityLevel': _activityLevel,
      'age': _age,
      'height': _height,
      'weight': _weight,
      'gender': _gender,
      'medicalConditions': _selectedMedicalConditions,
      'cuisines': _selectedCuisines,
      'dietaryRestrictions': _selectedDietaryRestrictions,
      'tags': _selectedTags,
    };

    return SummaryWidget(
      profileData: profileData,
      onEditSection: (section) {
        int targetStep = 0;
        switch (section) {
          case 'goal':       targetStep = 0; break;
          case 'activity':   targetStep = 1; break;
          case 'basic_info': targetStep = 2; break;
          case 'medical':    targetStep = 3; break;
          case 'food':       targetStep = 4; break;
          case 'tags':       targetStep = 5; break;
        }
        _goToStep(targetStep);
      },
    );
  }

  Widget _buildBottomNavigation() {
    final bool canContinue = _canContinueFromCurrentStep();
    final bool isLastStep = _currentStep == _totalSteps - 1;
    final bool canSkip = _canSkipCurrentStep();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canSkip && !isLastStep)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 2.h),
              child: TextButton(
                onPressed: _nextStep,
                child: Text(
                  'Skip for now',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'arrow_back',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 4.w,
                        ),
                        SizedBox(width: 2.w),
                        const Text('Back'),
                      ],
                    ),
                  ),
                ),
              if (_currentStep > 0) SizedBox(width: 4.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? (isLastStep ? _completeOnboarding : _nextStep)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canContinue
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                    foregroundColor: canContinue
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastStep ? 'Complete Profile' : 'Continue',
                        style: AppTheme.lightTheme.textTheme.labelLarge
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: canContinue
                              ? AppTheme.lightTheme.colorScheme.onPrimary
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!isLastStep) ...[
                        SizedBox(width: 2.w),
                        CustomIconWidget(
                          iconName: 'arrow_forward',
                          color: canContinue
                              ? AppTheme.lightTheme.colorScheme.onPrimary
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 4.w,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canContinueFromCurrentStep() {
    switch (_currentStep) {
      case 0: return _selectedGoal.isNotEmpty;
      case 1: return true;
      case 2: return _gender.isNotEmpty && _age > 0 && _height > 0 && _weight > 0;
      case 3: return true;
      case 4: return true;
      case 5: return true;
      case 6: return true;
      default: return false;
    }
  }

  bool _canSkipCurrentStep() {
    switch (_currentStep) {
      case 3: return true;
      case 4: return true;
      case 5: return true;
      default: return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 15.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Saving your profile...',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Setting up your personalised plan. This will take just a moment.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            LinearProgressIndicator(
              backgroundColor: AppTheme.lightTheme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final uid = FirebaseService.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      final existing =
          await FirebaseService.instance.clients.doc(uid).get();
      final alreadyHasStartingWeight =
          existing.exists && existing.data()?['startingWeightKg'] != null;

      // 1. Save health profile to clients collection
      await FirebaseService.instance.clients.doc(uid).set({
        'goal': _selectedGoal,
        'activityLevel': _activityLevel,
        'age': _age,
        'heightCm': _height,
        'weightKg': _weight,
        if (!alreadyHasStartingWeight) 'startingWeightKg': _weight,
        'gender': _gender,
        'medicalConditions': _selectedMedicalConditions,
        'cuisines': _selectedCuisines,
        'dietaryRestrictions': _selectedDietaryRestrictions,
        'tags': _selectedTags,
        if (!existing.exists) 'subscriptionStatus': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Mark onboarding complete — this is what the SplashScreen reads.
      //    MUST succeed before navigating away.
      await FirebaseService.instance.users.doc(uid).update({
        'onboardingComplete': true,
      });

      // 3. Only navigate after BOTH writes succeed — skip subscription page,
      //    user can subscribe from the dashboard whenever they're ready.
      if (mounted) {
        Navigator.of(context).pop(); // close loading dialog
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardHome);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      // Close loading dialog and show error — do NOT navigate away
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to save profile. Check your connection and try again.\n$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
