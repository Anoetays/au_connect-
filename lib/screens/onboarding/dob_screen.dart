import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/info_card.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class DOBScreen extends StatefulWidget {
  const DOBScreen({super.key});

  @override
  State<DOBScreen> createState() => _DOBScreenState();
}

class _DOBScreenState extends State<DOBScreen> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: PrimaryButton(
        label: 'Continue →',
        onTap: () {
          if (_value == null) {
            c.showToast(context, 'Please enter your date of birth');
            return;
          }
          c.state.dob = _value!.toIso8601String().split('T').first;
          c.goTo(11);
        },
      ),
      child: Column(
        children: [
          CrimsonHeader(icon: '📅', tag: 'Application • Step 2', title: 'When were you born?', subtitle: 'Your date of birth helps us verify eligibility', onBack: c.back),
          const ProgressBar(step: 2, total: 8, percent: 25),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(now.year - 18, 1, 1),
                      firstDate: DateTime(1960, 1, 1),
                      lastDate: DateTime(2010, 12, 31),
                    );
                    if (picked != null) {
                      setState(() => _value = picked);
                    }
                  },
                  child: Text(_value == null ? 'Select Date of Birth' : _value!.toIso8601String().split('T').first),
                ),
                const SizedBox(height: 12),
                const InfoCard(icon: '📋', title: 'Age Requirement', body: 'Applicants must be at least 16 years old to apply. Your age will be calculated automatically.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
