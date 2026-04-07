import 'package:flutter/material.dart';
import 'package:au_connect/screens/onboarding/onboarding_constants.dart';

class CrimsonHeader extends StatelessWidget {
  final String icon;
  final String tag;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const CrimsonHeader({
    super.key,
    required this.icon,
    required this.tag,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 54, 24, 28),
      decoration: const BoxDecoration(
        color: kCrimson,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          if (onBack != null)
            Positioned(
              top: -6,
              left: -4,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: onBack != null ? 40 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 14),
                Text(tag.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: Color(0x99FFFFFF), fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w600, height: 1.15)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF), height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
