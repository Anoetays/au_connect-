import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/info_card.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'package:au_connect/widgets/selectable_chip.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class ProgrammeScreen extends StatelessWidget {
  const ProgrammeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    final programmes = c.currentProgrammes();
    return OnboardingShell(
      footer: PrimaryButton(label: 'Continue →', isDisabled: c.state.programme.isEmpty, onTap: c.state.programme.isEmpty ? null : () => c.goTo(14)),
      child: Column(
        children: [
          CrimsonHeader(icon: '🧭', tag: 'Application • Step 4b', title: 'Choose a Programme', subtitle: 'Select the programme you wish to apply for', onBack: c.back),
          const ProgressBar(step: 4, total: 8, percent: 50),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                InfoCard(icon: '📋', title: 'Requirements', body: c.currentRequirement()),
                const SizedBox(height: 12),
                ...programmes.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SelectableChip(icon: '📄', label: p, isSelected: c.state.programme == p, onTap: () {
                    c.state.programme = p;
                    c.refresh();
                  }),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
