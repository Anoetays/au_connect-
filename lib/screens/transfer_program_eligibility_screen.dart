import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class TransferProgramEligibilityScreen extends StatelessWidget {
  const TransferProgramEligibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Program Eligibility')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Program Eligibility',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Based on your previous academic record, these programs are a strong match.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _buildProgramCard(
                context,
                programName: 'Bachelor of Business Administration',
                gpaRequirement: '3.0',
                missingPrerequisites: ['Calculus I'],
              ),
              const SizedBox(height: 16),
              _buildProgramCard(
                context,
                programName: 'Bachelor of Computer Science',
                gpaRequirement: '3.2',
                missingPrerequisites: ['Data Structures'],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(
    BuildContext context, {
    required String programName,
    required String gpaRequirement,
    required List<String> missingPrerequisites,
  }) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Symbols.school, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    programName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'GPA Requirement: $gpaRequirement',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (missingPrerequisites.isNotEmpty) ...[
              Text(
                'Missing prerequisites:',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...missingPrerequisites.map(
                (prereq) => Row(
                  children: [
                    Icon(Symbols.warning, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prereq,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
