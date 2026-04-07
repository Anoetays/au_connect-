import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'package:au_connect/widgets/selectable_chip.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class DisabilityScreen extends StatefulWidget {
  const DisabilityScreen({super.key});

  @override
  State<DisabilityScreen> createState() => _DisabilityScreenState();
}

class _DisabilityScreenState extends State<DisabilityScreen> {
  final _detail = TextEditingController();

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: PrimaryButton(
        label: 'Continue →',
        isDisabled: c.state.disability.isEmpty,
        onTap: c.state.disability.isEmpty
            ? null
            : () {
                c.state.disabilityDetail = _detail.text.trim();
                c.goTo(21);
              },
      ),
      child: Column(
        children: [
          CrimsonHeader(icon: '♿', tag: 'Application • Step 7b', title: 'Any accessibility needs?', subtitle: 'This helps AU prepare the right support for you', onBack: c.back),
          const ProgressBar(step: 7, total: 8, percent: 87),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SelectableChip(icon: '✅', label: 'No disabilities or special needs', isSelected: c.state.disability == 'none', onTap: () { c.state.disability = 'none'; c.refresh(); }),
                const SizedBox(height: 12),
                SelectableChip(icon: '♿', label: 'Yes, I have accessibility needs', desc: 'We\'ll make sure AU is prepared', isSelected: c.state.disability == 'has', onTap: () { c.state.disability = 'has'; c.refresh(); }),
                if (c.state.disability == 'has') ...[
                  const SizedBox(height: 12),
                  const Text('PLEASE DESCRIBE YOUR NEEDS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMid)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _detail,
                    maxLines: 3,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: kBackground),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
