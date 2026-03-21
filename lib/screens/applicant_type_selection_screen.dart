import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class ApplicantTypeSelectionScreen extends StatelessWidget {
  const ApplicantTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AU Connect'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Application Type',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Select the category that best describes your academic situation to start your journey with us.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 40),
              _SelectionCard(
                icon: Symbols.school,
                title: 'First-Year Application',
                description: 'High school students applying to university for the first time.',
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  '/applicant_dashboard',
                  arguments: 'First-Year',
                ),
              ),
              const SizedBox(height: 16),
              _SelectionCard(
                icon: Symbols.public,
                title: 'International Applicants',
                description: 'Students with citizenship outside Zimbabwe applying to study at Africa University.',
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  '/applicant_dashboard',
                  arguments: 'International',
                ),
              ),
              const SizedBox(height: 16),
              _SelectionCard(
                icon: Symbols.transfer_within_a_station,
                title: 'Transfer Applicants',
                description: 'Students currently enrolled at another university who want to transfer.',
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  '/applicant_dashboard',
                  arguments: 'Transfer',
                ),
              ),
              const SizedBox(height: 16),
              _SelectionCard(
                icon: Symbols.history_edu,
                title: 'Resumed Undergraduate Students',
                description: 'Students returning to university after interrupting their studies.',
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  '/applicant_dashboard',
                  arguments: 'Resumed',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28, fill: 1),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Symbols.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}