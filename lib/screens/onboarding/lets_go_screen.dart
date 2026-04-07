import 'package:flutter/material.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';

class LetsGoScreen extends StatelessWidget {
  const LetsGoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return Scaffold(
      backgroundColor: kCrimson,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('🚀', style: TextStyle(fontSize: 64)),
                    SizedBox(height: 16),
                    Text('Let\'s get started\nwith your application', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w600, height: 1.2)),
                    SizedBox(height: 12),
                    Text('We\'ll ask you a few quick questions. Most are just a tap — it takes less than 5 minutes.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xC0FFFFFF), height: 1.6)),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: PrimaryButton(label: 'Start My Application →', onTap: () => c.goTo(9)),
            ),
          ],
        ),
      ),
    );
  }
}
