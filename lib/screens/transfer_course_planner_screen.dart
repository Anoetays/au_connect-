import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class TransferCoursePlannerScreen extends StatelessWidget {
  const TransferCoursePlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Course Planner')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Planner',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'A semester-by-semester plan that adapts based on your transferred credits.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _buildSemesterPlanCard(
                context,
                semester: 'Semester 1',
                courses: ['MTH 101', 'ENG 101', 'CSC 110', 'ECO 101'],
              ),
              const SizedBox(height: 16),
              _buildSemesterPlanCard(
                context,
                semester: 'Semester 2',
                courses: ['MTH 102', 'ENG 102', 'CSC 120', 'BUS 101'],
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Graduation',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '2.5 years (based on current plan)',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterPlanCard(BuildContext context, {required String semester, required List<String> courses}) {
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
                  child: const Icon(Symbols.calendar_month, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    semester,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...courses.map(
              (course) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Symbols.check, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Text(course, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
