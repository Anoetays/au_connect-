import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class RegisterOnboardingScreen extends StatefulWidget {
  const RegisterOnboardingScreen({super.key});

  @override
  State<RegisterOnboardingScreen> createState() =>
      _RegisterOnboardingScreenState();
}

class _RegisterOnboardingScreenState extends State<RegisterOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: 'Create Account & Continue →',
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      c.doRegister(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please fill in all required fields correctly'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'By continuing, you agree to AU Connect\'s Terms of Service',
                  style: TextStyle(fontSize: 12, color: kTextLight),
                  textAlign: TextAlign.center,
                ),
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
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: _FormInput(
                            label: 'First Name',
                            validator: _validateName,
                            onChanged: (v) => c.state.firstName = v,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: _FormInput(
                            label: 'Last Name',
                            validator: _validateName,
                            onChanged: (v) => c.state.lastName = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FormInput(
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      onChanged: (v) => c.state.phone = v,
                    ),
                    const SizedBox(height: 12),
                    _FormInput(
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      onChanged: (v) => c.state.email = v,
                    ),
                    const SizedBox(height: 12),
                    _FormInput(
                      label: 'Password',
                      obscure: true,
                      validator: _validatePassword,
                      onChanged: (v) => c.state.password = v,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    if (v.trim().length < 2) return 'Must be at least 2 characters';
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(v.trim())) {
      return 'No numbers or special characters allowed';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a valid email address';
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(v.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a valid phone number';
    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 15) {
      return 'Please enter a valid phone number';
    }
    if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}

class _FormInput extends StatelessWidget {
  final String label;
  final bool obscure;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  const _FormInput({
    required this.label,
    required this.onChanged,
    this.obscure = false,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
              fontSize: 12, color: kTextMid, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            filled: true,
            fillColor: kBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kCrimson, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kCrimson, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
