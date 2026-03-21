import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';

class FinancialAssistanceScreen extends StatelessWidget {
  const FinancialAssistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Assistance'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scholarships & Funding Opportunities',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildScholarshipCard(
                    'Merit Scholarship',
                    'For high-achieving students with excellent academic records',
                    'GPA 3.5+, Full-time enrollment',
                    '\$5,000 per year',
                  ),
                  const SizedBox(height: 16),
                  _buildScholarshipCard(
                    'Need-Based Grant',
                    'Financial assistance for students demonstrating financial need',
                    'Demonstrated financial need, Full-time enrollment',
                    'Up to \$10,000 per year',
                  ),
                  const SizedBox(height: 16),
                  _buildScholarshipCard(
                    'STEM Excellence Award',
                    'For students pursuing STEM degrees',
                    'STEM major, GPA 3.0+, Full-time enrollment',
                    '\$3,000 per year',
                  ),
                  const SizedBox(height: 16),
                  _buildScholarshipCard(
                    'International Student Scholarship',
                    'For qualified international applicants',
                    'International student status, GPA 3.0+',
                    '\$7,000 per year',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScholarshipCard(String title, String description, String eligibility, String amount) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              'Eligibility: $eligibility',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: $amount',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Apply for scholarship
              },
              child: const Text('Apply Now'),
            ),
          ],
        ),
      ),
    );
  }
}