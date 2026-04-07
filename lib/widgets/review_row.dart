import 'package:flutter/material.dart';
import 'package:au_connect/screens/onboarding/onboarding_constants.dart';

class ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const ReviewRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: kTextLight, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value.isEmpty ? '—' : value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, color: kTextDark, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
