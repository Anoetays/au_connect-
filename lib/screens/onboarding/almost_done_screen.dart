import 'package:flutter/material.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';

class AlmostDoneScreen extends StatelessWidget {
  const AlmostDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return Scaffold(
      backgroundColor: kCrimson,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3)),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('90%', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w600)),
                    Text('Complete', style: TextStyle(color: Color(0xB3FFFFFF))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("You're almost done!", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Just two more steps: add your next of kin details and pay the application fee.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xC0FFFFFF))),
              const SizedBox(height: 20),
              PrimaryButton(label: "Let's Finish Up →", onTap: () => c.goTo(22)),
            ],
          ),
        ),
      ),
    );
  }
}
