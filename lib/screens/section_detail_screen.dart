import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';

class SectionDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
