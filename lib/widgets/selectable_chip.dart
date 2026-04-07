import 'package:flutter/material.dart';
import 'package:au_connect/screens/onboarding/onboarding_constants.dart';

class SelectableChip extends StatelessWidget {
  final String icon;
  final String label;
  final String? desc;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableChip({
    super.key,
    required this.icon,
    required this.label,
    this.desc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kCrimsonMuted : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? kCrimson : kBorder, width: 2),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
                  if (desc != null && desc!.isNotEmpty)
                    Text(desc!, style: const TextStyle(fontSize: 11, color: kTextLight)),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: kCrimson, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('✓', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}
