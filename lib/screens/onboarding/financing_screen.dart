import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'package:au_connect/widgets/selectable_chip.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class FinancingScreen extends StatelessWidget {
  const FinancingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      child: Column(
        children: [
          CrimsonHeader(icon: '💸', tag: 'Application • Step 6', title: 'How will you finance your studies?', subtitle: 'This helps us identify support options for you', onBack: c.back),
          const ProgressBar(step: 6, total: 8, percent: 75),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SelectableChip(icon: '💰', label: 'Self-Sponsored', desc: 'I or my family will cover all fees', isSelected: c.state.financing == 'Self-sponsored', onTap: () {
                  c.state.financing = 'Self-sponsored';
                  c.refresh();
                  c.goTo(18); // ResidencyCheckScreen
                }),
                const SizedBox(height: 12),
                SelectableChip(icon: '🏆', label: 'Full Scholarship', desc: 'I have or am applying for a full scholarship', isSelected: c.state.financing == 'Full Scholarship', onTap: () {
                  c.state.financing = 'Full Scholarship';
                  c.refresh();
                  c.goTo(18); // ResidencyCheckScreen
                }),
                const SizedBox(height: 12),
                SelectableChip(icon: '🤝', label: 'Partial Scholarship', desc: 'I have partial funding and will cover the rest', isSelected: c.state.financing == 'Partial Scholarship', onTap: () {
                  c.state.financing = 'Partial Scholarship';
                  c.refresh();
                  c.goTo(18); // ResidencyCheckScreen
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
