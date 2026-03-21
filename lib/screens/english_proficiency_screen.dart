import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

enum ProficiencyStatus { pending, submitted, verified, waived }

class EnglishProficiencyScreenResult {
  final ProficiencyStatus status;

  EnglishProficiencyScreenResult({required this.status});
}

class EnglishProficiencyScreen extends StatefulWidget {
  final ProficiencyStatus initialStatus;

  const EnglishProficiencyScreen({
    super.key,
    this.initialStatus = ProficiencyStatus.pending,
  });

  @override
  State<EnglishProficiencyScreen> createState() => _EnglishProficiencyScreenState();
}

class _EnglishProficiencyScreenState extends State<EnglishProficiencyScreen> {
  late ProficiencyStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  Color _statusColor(ThemeData theme) {
    switch (_status) {
      case ProficiencyStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
      case ProficiencyStatus.submitted:
        return AppTheme.primary;
      case ProficiencyStatus.verified:
        return Colors.green;
      case ProficiencyStatus.waived:
        return Colors.orange;
    }
  }

  String _statusLabel() {
    switch (_status) {
      case ProficiencyStatus.pending:
        return 'Pending';
      case ProficiencyStatus.submitted:
        return 'Submitted';
      case ProficiencyStatus.verified:
        return 'Verified';
      case ProficiencyStatus.waived:
        return 'Waived';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('English Proficiency'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IELTS / TOEFL Status',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Symbols.language, color: _statusColor(theme)),
                const SizedBox(width: 10),
                Text(
                  _statusLabel(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _statusColor(theme),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Upload your exam report or request a waiver if you meet the requirements.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            _buildActionButton(
              icon: Symbols.upload_file,
              label: 'Upload Test Scores',
              onPressed: () {
                setState(() {
                  _status = ProficiencyStatus.submitted;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Symbols.shield,
              label: 'Request Waiver',
              onPressed: () {
                setState(() {
                  _status = ProficiencyStatus.waived;
                });
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    EnglishProficiencyScreenResult(status: _status),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save & Return'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppTheme.primary),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: AppTheme.primary,
        ),
      ),
    );
  }
}
