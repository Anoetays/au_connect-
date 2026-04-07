import 'package:flutter/material.dart';

import 'academic_screen.dart';
import 'accommodation_screen.dart';
import 'alevel_screen.dart';
import 'almost_done_screen.dart';
import 'country_screen.dart';
import 'disability_screen.dart';
import 'disqualified_screen.dart';
import 'dob_screen.dart';
import 'field_of_study_screen.dart';
import 'financing_screen.dart';
import 'gender_screen.dart';
import 'greeting_screen.dart';
import 'language_screen.dart';
import 'lets_go_screen.dart';
import 'name_in_language_screen.dart';
import 'next_of_kin_screen.dart';
import 'onboarding_controller.dart';
import 'residency_check_screen.dart';
import 'onboarding_scope.dart';
import 'payment_screen.dart';
import 'programme_screen.dart';
import 'register_screen.dart';
import 'review_screen.dart';
import 'role_screen.dart';
import 'splash_screen.dart';
import 'study_level_screen.dart';
import 'success_screen.dart';
import 'tracker_screen.dart';
import 'welcome_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final OnboardingController _controller = OnboardingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final screens = <Widget>[
            const SplashScreen(),
            const WelcomeOnboardingScreen(),
            const RegisterOnboardingScreen(),
            const CountryScreen(),
            const LanguageScreen(),
            const NameInLanguageScreen(),
            const GreetingScreen(),
            const RoleScreen(),
            const LetsGoScreen(),
            const GenderScreen(),
            const DOBScreen(),
            const StudyLevelScreen(),
            const FieldOfStudyScreen(),
            const ProgrammeScreen(),
            const ALevelScreen(),
            const DisqualifiedScreen(),
            const AcademicScreen(),
            const FinancingScreen(),
            const ResidencyCheckScreen(),
            const AccommodationScreen(),
            const DisabilityScreen(),
            const AlmostDoneScreen(),
            const NextOfKinScreen(),
            const PaymentScreen(),
            const ReviewScreen(),
            const SuccessScreen(),
            const TrackerScreen(),
          ];
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey<int>(_controller.index),
              child: screens[_controller.index],
            ),
          );
        },
      ),
    );
  }
}
