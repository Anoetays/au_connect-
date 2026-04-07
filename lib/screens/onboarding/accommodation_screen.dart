import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'package:au_connect/widgets/selectable_chip.dart';
import 'package:au_connect/widgets/warning_card.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class AccommodationScreen extends StatelessWidget {
  const AccommodationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    final isOff = c.state.accommodation == 'Off Campus';
    return OnboardingShell(
      footer: PrimaryButton(label: 'Continue →', isDisabled: c.state.accommodation.isEmpty, onTap: c.state.accommodation.isEmpty ? null : () => c.goTo(20)),
      child: Column(
        children: [
          CrimsonHeader(icon: '🏠', tag: 'Application • Step 7', title: 'Where will you stay?', subtitle: 'Choose your preferred accommodation', onBack: c.back),
          const ProgressBar(step: 7, total: 8, percent: 87),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(child: SelectableChip(icon: '🏠', label: 'On Campus', desc: 'AU residence halls', isSelected: c.state.accommodation == 'On Campus', onTap: () { c.state.accommodation = 'On Campus'; c.refresh(); })),
                    const SizedBox(width: 12),
                    Expanded(child: SelectableChip(icon: '🏘️', label: 'Off Campus', desc: 'Private accommodation', isSelected: isOff, onTap: () { c.state.accommodation = 'Off Campus'; c.refresh(); })),
                  ],
                ),
                if (isOff) ...[
                  const SizedBox(height: 12),
                  const WarningCard(body: 'You\'ve chosen to live off campus. Please ensure you\'ve arranged suitable accommodation near AU. The university will not be responsible for off-campus arrangements.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
