import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/selectable_chip.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: PrimaryButton(label: 'Proceed to Review →', onTap: () => c.goTo(24)),
      child: Column(
        children: [
          CrimsonHeader(icon: '💳', tag: 'Application Fee', title: 'Pay Application Fee', subtitle: 'A one-time non-refundable fee to submit your application', onBack: c.back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: kCrimson, borderRadius: BorderRadius.circular(20)),
                  child: const Column(
                    children: [
                      Text('Application Fee', style: TextStyle(color: Color(0x99FFFFFF), letterSpacing: 1, fontSize: 12)),
                      SizedBox(height: 8),
                        Text('\$30', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w400)),
                      SizedBox(height: 4),
                      Text('USD · One-time payment', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SelectableChip(icon: '📱', label: 'EcoCash (Paynow)', desc: 'Pay with your mobile wallet', isSelected: c.state.paymentMethod == 'EcoCash', onTap: () { c.state.paymentMethod = 'EcoCash'; c.refresh(); }),
                const SizedBox(height: 12),
                SelectableChip(icon: '💳', label: 'Visa / Mastercard', desc: 'Powered by Flutterwave', isSelected: c.state.paymentMethod == 'Card', onTap: () { c.state.paymentMethod = 'Card'; c.refresh(); }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
