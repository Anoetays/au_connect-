import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/info_card.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'package:au_connect/widgets/selectable_chip.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class ALevelScreen extends StatelessWidget {
  const ALevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    final question = 'Hey ${c.state.preferredName}! ${c.currentALevelMsg()}';
    return OnboardingShell(
      footer: PrimaryButton(
        label: 'Continue →',
        isDisabled: c.state.aLevelQualified.isEmpty,
        onTap: c.state.aLevelQualified.isEmpty
            ? null
            : () => c.goTo(c.state.aLevelQualified == 'yes' ? 16 : 15),
      ),
      child: Column(
        children: [
          CrimsonHeader(icon: '✅', tag: 'Eligibility Check', title: question, subtitle: 'Be honest — this helps us guide you to the right programme', onBack: c.back),
          const ProgressBar(step: 4, total: 8, percent: 50),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                InfoCard(icon: '📋', title: 'Requirement', body: c.currentRequirement()),
                const SizedBox(height: 12),
                SelectableChip(icon: '✅', label: 'Yes, I qualify', isSelected: c.state.aLevelQualified == 'yes', onTap: () {
                  c.state.aLevelQualified = 'yes';
                  c.refresh();
                }),
                const SizedBox(height: 12),
                SelectableChip(icon: '❌', label: "No, I don't", isSelected: c.state.aLevelQualified == 'no', onTap: () {
                  c.state.aLevelQualified = 'no';
                  c.refresh();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
