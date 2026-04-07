import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'package:au_connect/widgets/selectable_chip.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class FieldOfStudyScreen extends StatelessWidget {
  const FieldOfStudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: PrimaryButton(
        label: 'View Programmes →',
        isDisabled: c.state.field.isEmpty,
        onTap: c.state.field.isEmpty ? null : () => c.goTo(13),
      ),
      child: Column(
        children: [
          CrimsonHeader(icon: '📚', tag: 'Application • Step 4', title: 'Which field interests you?', subtitle: 'Choose a faculty to explore', onBack: c.back),
          const ProgressBar(step: 4, total: 8, percent: 50),
          Expanded(
            child: GridView(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
              children: [
                SelectableChip(icon: '💻', label: 'Technology', desc: 'CS, AI, Engineering', isSelected: c.state.field == 'Technology', onTap: () { c.state.field = 'Technology'; c.refresh(); }),
                SelectableChip(icon: '🏥', label: 'Health Science', desc: 'Medical, Agri, Social', isSelected: c.state.field == 'HealthScience', onTap: () { c.state.field = 'HealthScience'; c.refresh(); }),
                SelectableChip(icon: '💼', label: 'Business', desc: 'Accounting, Management', isSelected: c.state.field == 'Business', onTap: () { c.state.field = 'Business'; c.refresh(); }),
                SelectableChip(icon: '✝️', label: 'Theology', desc: 'Divinity, Biblical Studies', isSelected: c.state.field == 'Theology', onTap: () { c.state.field = 'Theology'; c.refresh(); }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
