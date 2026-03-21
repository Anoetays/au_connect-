import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class TransferAdvisorSupportScreen extends StatelessWidget {
  const TransferAdvisorSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Advisor Support')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advisor Support',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Need help planning your transfer? Reach out to our transfer advisors for guidance.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _buildContactCard(
                context,
                icon: Symbols.chat,
                title: 'Chat with an advisor',
                subtitle: 'Start a live chat with our transfer support team.',
                buttonLabel: 'Start chat',
                onPressed: () => Navigator.pop(context, 'Chat session started'),
              ),
              const SizedBox(height: 16),
              _buildContactCard(
                context,
                icon: Symbols.event,
                title: 'Book an appointment',
                subtitle: 'Schedule a one-on-one session with a transfer advisor.',
                buttonLabel: 'Book now',
                onPressed: () => Navigator.pop(context, 'Appointment booked'),
              ),
              const SizedBox(height: 24),
              Text(
                'Transfer FAQs',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFaqItem(context, 'How do I submit my transcripts?'),
              _buildFaqItem(context, 'What is the credit evaluation process?'),
              _buildFaqItem(context, 'How long does transfer approval take?'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
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

  Widget _buildFaqItem(BuildContext context, String question) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        title: Text(question, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        trailing: Icon(Symbols.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        onTap: () {},
      ),
    );
  }
}
