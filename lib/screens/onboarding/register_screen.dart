import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class RegisterOnboardingScreen extends StatelessWidget {
  const RegisterOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(label: 'Create Account & Continue →', onTap: () => c.doRegister(context)),
                const SizedBox(height: 10),
                const Text('By continuing, you agree to AU Connect\'s Terms of Service', style: TextStyle(fontSize: 12, color: kTextLight), textAlign: TextAlign.center),
              ],
            ),
      child: Column(
        children: [
          CrimsonHeader(
            icon: '📝',
            tag: 'Step 1 of 2',
            title: 'Create your account',
            subtitle: 'Let\'s get you set up in under a minute',
            onBack: c.back,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: _Input(label: 'First Name', onChanged: (v) => c.state.firstName = v)),
                      const SizedBox(width: 12),
                      Flexible(child: _Input(label: 'Last Name', onChanged: (v) => c.state.lastName = v)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Input(label: 'Phone Number', onChanged: (v) => c.state.phone = v),
                  const SizedBox(height: 12),
                  _Input(label: 'Email Address', onChanged: (v) => c.state.email = v),
                  const SizedBox(height: 12),
                  _Input(label: 'Password', obscure: true, onChanged: (v) => c.state.password = v),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final bool obscure;
  final ValueChanged<String> onChanged;
  const _Input({required this.label, required this.onChanged, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, color: kTextMid, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        obscureText: obscure,
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: kBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder, width: 1.5)),
        ),
      ),
    ]);
  }
}
