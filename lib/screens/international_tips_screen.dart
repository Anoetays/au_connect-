import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class InternationalTipsScreen extends StatelessWidget {
  const InternationalTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips for International Students'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Tips',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTip(context, Symbols.timer, 'Apply for your visa early to avoid delays.'),
            _buildTip(context, Symbols.verified, 'Ensure your passport is valid for at least 6 months.'),
            _buildTip(context, Symbols.document_scanner,
                'Get your documents certified before submission where required.'),
            _buildTip(context, Symbols.schedule, 'Plan your travel dates around orientation and registration.'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
