import 'package:flutter/material.dart';

class WarningCard extends StatelessWidget {
  final String body;
  const WarningCard({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              body,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7D5200), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
