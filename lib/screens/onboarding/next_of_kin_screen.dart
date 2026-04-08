import 'package:flutter/material.dart';
import 'package:au_connect/widgets/country_chip.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class NextOfKinScreen extends StatefulWidget {
  const NextOfKinScreen({super.key});

  @override
  State<NextOfKinScreen> createState() => _NextOfKinScreenState();
}

class _NextOfKinScreenState extends State<NextOfKinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter the full name';
    if (v.trim().length < 2) return 'Must be at least 2 characters';
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(v.trim())) {
      return 'No numbers or special characters allowed';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a valid phone number';
    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 15) {
      return 'Must be 9–15 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: PrimaryButton(
        label: 'Continue →',
        onTap: () {
          if (c.state.kinRel.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a relationship'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          if (_formKey.currentState!.validate()) {
            c.state.kinName = _name.text.trim();
            c.state.kinPhone = _phone.text.trim();
            c.goTo(23);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please fill in all required fields correctly'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
      child: Column(
        children: [
          CrimsonHeader(
            icon: '👤',
            tag: 'Application • Step 8',
            title: 'Next of Kin Details',
            subtitle: 'Emergency contact information',
            onBack: c.back,
          ),
          const ProgressBar(step: 8, total: 8, percent: 95),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FULL NAME',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kTextMid),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _name,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _validateName,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: kBackground,
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: kCrimson, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: kCrimson, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'RELATIONSHIP',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kTextMid),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 2.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    CountryChip(
                        flag: '👨‍👩‍👦',
                        name: 'Parent',
                        isSelected: c.state.kinRel == 'Parent',
                        onTap: () {
                          c.state.kinRel = 'Parent';
                          c.refresh();
                        }),
                    CountryChip(
                        flag: '👫',
                        name: 'Sibling',
                        isSelected: c.state.kinRel == 'Sibling',
                        onTap: () {
                          c.state.kinRel = 'Sibling';
                          c.refresh();
                        }),
                    CountryChip(
                        flag: '🤝',
                        name: 'Guardian',
                        isSelected: c.state.kinRel == 'Guardian',
                        onTap: () {
                          c.state.kinRel = 'Guardian';
                          c.refresh();
                        }),
                    CountryChip(
                        flag: '💑',
                        name: 'Spouse',
                        isSelected: c.state.kinRel == 'Spouse',
                        onTap: () {
                          c.state.kinRel = 'Spouse';
                          c.refresh();
                        }),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'PHONE NUMBER',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kTextMid),
                ),
                const SizedBox(height: 6),
                Form(
                  child: TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validatePhone,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: kBackground,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: kCrimson, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: kCrimson, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
