import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/info_card.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/review_row.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : PrimaryButton(label: '✅ Confirm & Submit Application', onTap: () => c.doSubmit(context)),
      child: Column(
        children: [
          CrimsonHeader(icon: '🔎', tag: 'Final Step', title: 'Review & Submit', subtitle: 'Check your details before submitting', onBack: c.back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8D5D7), width: 1.5)),
                  child: Column(
                    children: [
                      ReviewRow(label: 'Name', value: c.state.preferredName.isEmpty ? '${c.state.firstName} ${c.state.lastName}'.trim() : c.state.preferredName),
                      ReviewRow(label: 'Email', value: c.state.email),
                      ReviewRow(label: 'Gender', value: c.state.gender),
                      ReviewRow(label: 'Date of Birth', value: c.state.dob),
                      ReviewRow(label: 'Country', value: c.state.country),
                      ReviewRow(label: 'Level', value: c.state.studyLevel),
                      ReviewRow(label: 'Programme', value: c.state.programme),
                      ReviewRow(label: 'Financing', value: c.state.financing),
                      ReviewRow(label: 'Accommodation', value: c.state.accommodation),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const InfoCard(icon: '🔒', title: 'Confirmation', body: 'By submitting, you confirm that all information provided is accurate and complete.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
