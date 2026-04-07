import 'package:flutter/material.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';

class GreetingScreen extends StatelessWidget {
  const GreetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return Scaffold(
      backgroundColor: kCrimson,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👋', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text(
                '${c.greetingHello()} ${c.state.preferredName}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.w600, height: 1.1),
              ),
              const SizedBox(height: 8),
              Text(c.greetingWelcome(), style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 18)),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Column(
                  children: [
                    _row('Name', c.state.preferredName),
                    const SizedBox(height: 8),
                    _row('Country', c.state.country),
                    const SizedBox(height: 8),
                    _row('Language', c.state.language),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(label: 'Let\'s Begin →', onTap: () => c.goTo(7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String key, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
