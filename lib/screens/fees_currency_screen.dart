import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class FeesCurrencyScreen extends StatefulWidget {
  const FeesCurrencyScreen({super.key});

  @override
  State<FeesCurrencyScreen> createState() => _FeesCurrencyScreenState();
}

class _FeesCurrencyScreenState extends State<FeesCurrencyScreen> {
  bool _showUsd = true;

  double get _tuitionAmount => _showUsd ? 4500 : 2100000;
  String get _currencyLabel => _showUsd ? 'USD' : 'ZWL';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fees & Currency'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tuition Fees',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${_tuitionAmount.toStringAsFixed(0)} $_currencyLabel',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                ToggleButtons(
                  isSelected: [_showUsd, !_showUsd],
                  onPressed: (index) {
                    setState(() {
                      _showUsd = index == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.white,
                  color: theme.colorScheme.onSurface,
                  fillColor: AppTheme.primary,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.0),
                      child: Text('USD'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.0),
                      child: Text('ZWL'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Methods',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildMethodTile(
              icon: Symbols.account_balance,
              title: 'Bank Transfer',
              subtitle: 'Use our official bank details to transfer funds.',
            ),
            const SizedBox(height: 12),
            _buildMethodTile(
              icon: Symbols.credit_card,
              title: 'International Card',
              subtitle: 'Pay using Visa or Mastercard from abroad.',
            ),
            const SizedBox(height: 24),
            Text(
              'Tips',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Exchange rates can change daily. Check with your bank before transferring funds.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
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

  Widget _buildMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
