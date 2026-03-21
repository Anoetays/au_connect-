import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';

class ActivitiesAchievementsScreen extends StatelessWidget {
  const ActivitiesAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities & Achievements'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your extracurriculars',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This section will let you list clubs, awards, volunteer experiences, and other achievements.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Text('Back to Dashboard'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Text('Mark Complete'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
