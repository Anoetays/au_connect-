import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/info_card.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class NameInLanguageScreen extends StatefulWidget {
  const NameInLanguageScreen({super.key});

  @override
  State<NameInLanguageScreen> createState() => _NameInLanguageScreenState();
}

class _NameInLanguageScreenState extends State<NameInLanguageScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    final labels = c.nameLabels();

    return OnboardingShell(
      footer: PrimaryButton(
        label: 'Continue →',
        onTap: () {
          final name = _controller.text.trim();
          if (name.isEmpty) {
            c.showToast(context, 'Please enter your name');
            return;
          }
          c.state.preferredName = name;
          c.goTo(6);
        },
      ),
      child: Column(
        children: [
          CrimsonHeader(
            icon: '✍️',
            tag: 'Almost There',
            title: labels['title']!,
            subtitle: labels['sub']!,
            onBack: c.back,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(labels['label']!.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: const Color(0xFFFBF8F8),
                  ),
                ),
                const SizedBox(height: 12),
                const InfoCard(icon: '💡', title: 'Tip', body: 'This is how AU Connect will greet you throughout the app.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
