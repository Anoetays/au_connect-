import 'package:flutter/material.dart';
import 'package:au_connect/screens/onboarding_dashboard_screen.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_scope.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    final isInternational = c.state.applicantType == 'international';
    final msg =
        '${c.greetingHello()} ${c.state.preferredName}! You have successfully applied for ${c.state.programme} at Africa University. We will notify you of the outcome.';

    return Scaffold(
      backgroundColor: const Color(0xFF1A7A4A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text('🎉', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 20),
              const Text(
                'Congratulations!',
                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xC0FFFFFF), height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Applied For',
                      style: TextStyle(color: Color(0x99FFFFFF), letterSpacing: 1, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.state.programme,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ],
                ),
              ),

              // ── Visa alert card (international only) ──────────────
              if (isInternational) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF5E6),
                    border: Border.all(color: const Color(0xFFE8C84A), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🛂', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Visa & Study Permit Required',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF7A5C00),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'As an international student not residing in Zimbabwe, you need to apply for a Student Visa and Study Permit before enrolling.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A6A00),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/visa_guidance'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC9952A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Start Visa Guidance',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.chevron_right_rounded, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              PrimaryButton(
                label: 'View Application Status →',
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnboardingDashboardScreen(),
                  ),
                  (route) => false,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
