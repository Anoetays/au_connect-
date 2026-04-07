import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/selectable_chip.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      child: Column(
        children: [
          const CrimsonHeader(icon: '🎯', tag: 'Your Journey', title: 'Which role best describes you?', subtitle: 'We\'ll personalise your experience'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SelectableChip(
                  icon: '🎓',
                  label: 'Aspiring AU Student',
                  desc: 'I want to apply to Africa University',
                  isSelected: c.state.role == 'applicant',
                  onTap: () {
                    c.state.role = 'applicant';
                    c.refresh();
                    c.goTo(8);
                  },
                ),
                const SizedBox(height: 12),
                SelectableChip(icon: '📚', label: 'Current AU Student', desc: 'I\'m already enrolled at AU', isSelected: false, onTap: () => c.showToast(context, 'Coming soon')),
                const SizedBox(height: 12),
                SelectableChip(icon: '👨‍🏫', label: 'AU Staff', desc: 'I work at Africa University', isSelected: false, onTap: () => c.showToast(context, 'Coming soon')),
                const SizedBox(height: 12),
                SelectableChip(icon: '🛡️', label: 'Administration', desc: 'I manage AU operations', isSelected: c.state.role == 'admin', onTap: () {
                    c.state.role = 'admin';
                    c.refresh();
                    Navigator.pushReplacementNamed(context, '/admin_dashboard');
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
