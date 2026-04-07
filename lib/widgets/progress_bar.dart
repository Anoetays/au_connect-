import 'package:flutter/material.dart';
import 'package:au_connect/screens/onboarding/onboarding_constants.dart';

class ProgressBar extends StatelessWidget {
  final int step;
  final int total;
  final int percent;
  const ProgressBar({
    super.key,
    required this.step,
    required this.total,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step $step of $total', style: const TextStyle(fontSize: 11, color: kTextLight, fontWeight: FontWeight.w500)),
              Text('$percent%', style: const TextStyle(fontSize: 11, color: kTextLight, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 4,
              backgroundColor: kBorder,
              valueColor: const AlwaysStoppedAnimation(kCrimson),
            ),
          ),
        ],
      ),
    );
  }
}
