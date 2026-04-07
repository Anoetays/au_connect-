import 'package:flutter/material.dart';
import 'package:au_connect/screens/onboarding/onboarding_constants.dart';

class InfoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCrimsonMuted,
        border: Border.all(color: const Color.fromRGBO(178, 34, 52, 0.2), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kCrimsonDark)),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(fontSize: 13, color: kCrimsonDark, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const kCrimsonDark = Color(0xFF8B1A27);
