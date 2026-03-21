import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/models/transfer_data.dart';

class TransferCreditEvaluationScreen extends StatelessWidget {
  final TransferStage currentStage;

  const TransferCreditEvaluationScreen({
    super.key,
    this.currentStage = TransferStage.creditEvaluation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Evaluation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credit Evaluation',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload your transcripts and course outlines to get an initial evaluation of transferable credits.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                context,
                icon: Symbols.upload_file,
                title: 'Upload Transcripts',
                subtitle: 'Add your transcript files so we can compare them with AU equivalencies.',
                buttonLabel: 'Upload',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context,
                icon: Symbols.auto_stories,
                title: 'Evaluation Summary',
                subtitle: 'See how many credits have been accepted, rejected, or are pending.',
                buttonLabel: 'View Summary',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              _buildCourseMappingCard(context),
              const SizedBox(height: 20),
              if (currentStage == TransferStage.creditEvaluation)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, TransferStage.approved),
                  child: const Text('Mark Evaluation Complete'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
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
                  child: Icon(icon, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseMappingCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Equivalency Mapping',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Previous course → AU equivalent',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
              },
              children: const [
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Previous Course', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('AU Equivalent', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Intro to Economics'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('ECO 101'),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Calculus I'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('MTH 101'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
