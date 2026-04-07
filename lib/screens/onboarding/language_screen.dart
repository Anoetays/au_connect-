import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    const items = [
      ('🇬🇧', 'English', 'English'),
      ('🇫🇷', 'French', 'Francais'),
      ('🇵🇹', 'Portuguese', 'Portugues'),
      ('🌍', 'Swahili', 'Kiswahili'),
    ];

    return OnboardingShell(
      footer: PrimaryButton(
        label: 'Continue →',
        isDisabled: c.state.language.isEmpty,
        onTap: c.state.language.isEmpty ? null : () => c.goTo(5),
      ),
      child: Column(
        children: [
          CrimsonHeader(icon: '💬', tag: 'Preference', title: 'Choose your language', subtitle: 'Which language are you most comfortable with?', onBack: c.back),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.95, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemBuilder: (_, i) {
                  final it = items[i];
                  final selected = c.state.language == it.$2;
                  return InkWell(
                    onTap: () {
                      c.state.language = it.$2;
                      c.refresh();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected ? kCrimsonMuted : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? kCrimson : kBorder, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(it.$1, style: const TextStyle(fontSize: 34)),
                          const SizedBox(height: 8),
                          Text(it.$2, style: const TextStyle(fontWeight: FontWeight.w700, color: kTextDark)),
                          const SizedBox(height: 2),
                          Text(it.$3, style: const TextStyle(fontSize: 12, color: kTextLight)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
