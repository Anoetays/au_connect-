import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/secondary_button.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';

class WelcomeOnboardingScreen extends StatelessWidget {
  const WelcomeOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCrimson,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Text('🎓', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Your Future\nStarts Here', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w600, height: 1.2)),
            const SizedBox(height: 8),
            const Text('Africa University Admissions', style: TextStyle(color: Color(0xB3FFFFFF))),
            const SizedBox(height: 28),
            kIsWeb
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _buildWelcomeCard(context),
                    ),
                  )
                : _buildWelcomeCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final c = OnboardingScope.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Transform.translate(
            offset: const Offset(0, -54),
            child: Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24)],
              ),
              child: const Icon(Icons.school_rounded, size: 80, color: Color(0xFFB91C1C)),
            ),
          ),
          const Text('Welcome to\nAU Connect', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, color: kTextDark, height: 1.2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          const Text('Your seamless gateway to Africa University. Apply, track, and manage your admissions journey — all in one place.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: kTextMid, height: 1.5)),
          const SizedBox(height: 22),
          PrimaryButton(label: 'Create Account →', onTap: () => c.goTo(2)),
          const SizedBox(height: 10),
          SecondaryButton(label: 'I already have an account', onTap: () => Navigator.pushNamed(context, '/applicant_sign_in')),
        ],
      ),
    );
  }
}
