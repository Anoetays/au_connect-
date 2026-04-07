import 'package:flutter/material.dart';
import 'onboarding_controller.dart';

class OnboardingScope extends InheritedNotifier<OnboardingController> {
  const OnboardingScope({
    super.key,
    required OnboardingController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static OnboardingController of(BuildContext context) {
    final OnboardingScope? scope =
        context.dependOnInheritedWidgetOfExactType<OnboardingScope>();
    assert(scope != null, 'OnboardingScope not found in widget tree');
    return scope!.notifier!;
  }
}
