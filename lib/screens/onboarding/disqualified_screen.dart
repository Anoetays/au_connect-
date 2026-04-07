import 'package:flutter/material.dart';
import 'package:au_connect/widgets/info_card.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/secondary_button.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class DisqualifiedScreen extends StatelessWidget {
  const DisqualifiedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😔', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              const Text('You don\'t qualify\nfor this programme', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Text('Unfortunately, you need the required A-level subjects to apply for this programme. But other great programmes at AU may be a perfect fit.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const InfoCard(icon: '💡', title: 'Try these instead', body: 'Business programmes, Health Sciences, or Theology — which have different requirements.'),
              const SizedBox(height: 16),
              PrimaryButton(label: '← Explore Other Fields', onTap: () => c.goTo(12)),
              const SizedBox(height: 10),
              SecondaryButton(label: 'Start Over', onTap: () => c.goTo(1)),
            ],
          ),
        ),
      ),
    );
  }
}
