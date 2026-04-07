import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'package:au_connect/widgets/selectable_chip.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class StudyLevelScreen extends StatelessWidget {
  const StudyLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      child: Column(
        children: [
          CrimsonHeader(icon: '🎯', tag: 'Application • Step 3', title: 'Which level of study?', subtitle: 'Choose the programme level you want to pursue', onBack: c.back),
          const ProgressBar(step: 3, total: 8, percent: 37),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SelectableChip(icon: '🎓', label: 'Undergraduate', desc: 'Bachelor\'s degree programmes', isSelected: c.state.studyLevel == 'Undergraduate', onTap: () {
                  c.state.studyLevel = 'Undergraduate';
                  c.refresh();
                  c.goTo(12);
                }),
                const SizedBox(height: 12),
                SelectableChip(icon: '🏅', label: 'Postgraduate', desc: 'Diploma or certificate after a degree', isSelected: c.state.studyLevel == 'Postgraduate', onTap: () {
                  c.state.studyLevel = 'Postgraduate';
                  c.refresh();
                  c.goTo(12);
                }),
                const SizedBox(height: 12),
                SelectableChip(icon: '🔬', label: 'Master\'s', desc: 'Advanced research or coursework degree', isSelected: c.state.studyLevel == 'Masters', onTap: () {
                  c.state.studyLevel = 'Masters';
                  c.refresh();
                  c.goTo(12);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
