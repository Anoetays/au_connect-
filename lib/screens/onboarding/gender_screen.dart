import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class GenderScreen extends StatelessWidget {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    final title = 'Hey ${c.state.preferredName.isEmpty ? '' : c.state.preferredName}! What\'s your gender?';
    return OnboardingShell(
      footer: PrimaryButton(label: 'Continue →', isDisabled: c.state.gender.isEmpty, onTap: c.state.gender.isEmpty ? null : () => c.goTo(10)),
      child: Column(
        children: [
          CrimsonHeader(icon: '👥', tag: 'Application • Step 1', title: title.trim(), subtitle: 'Tap to select', onBack: c.back),
          const ProgressBar(step: 1, total: 8, percent: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: _genderTile('👩', 'Female', c.state.gender == 'Female', () {
                        c.state.gender = 'Female';
                        c.refresh();
                      }),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: _genderTile('👨', 'Male', c.state.gender == 'Male', () {
                        c.state.gender = 'Male';
                        c.refresh();
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderTile(String emoji, String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5E6E8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFFB22234) : const Color(0xFFE8D5D7), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
