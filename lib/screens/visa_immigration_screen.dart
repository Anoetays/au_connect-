import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/models/visa_status.dart';

enum DocumentStatus { pending, uploaded, verified, rejected }

class VisaImmigrationScreenResult {
  final VisaStatus status;
  final Map<String, DocumentStatus> checklist;

  VisaImmigrationScreenResult({
    required this.status,
    required this.checklist,
  });
}

class VisaImmigrationScreen extends StatefulWidget {
  final VisaStatus initialStatus;
  final Map<String, DocumentStatus>? initialChecklist;

  const VisaImmigrationScreen({
    super.key,
    this.initialStatus = VisaStatus.notStarted,
    this.initialChecklist,
  });

  @override
  State<VisaImmigrationScreen> createState() => _VisaImmigrationScreenState();
}

class _VisaImmigrationScreenState extends State<VisaImmigrationScreen> {
  late VisaStatus _visaStatus;
  late Map<String, DocumentStatus> _checklist;

  @override
  void initState() {
    super.initState();
    _visaStatus = widget.initialStatus;
    _checklist = {
      'Passport Copy': DocumentStatus.pending,
      'Proof of Funds': DocumentStatus.pending,
      'Admission Letter': DocumentStatus.pending,
      ...?widget.initialChecklist,
    };
  }

  void _updateStatus(VisaStatus status) {
    setState(() {
      _visaStatus = status;
    });
  }

  void _cycleItemStatus(String item) {
    setState(() {
      final current = _checklist[item] ?? DocumentStatus.pending;
      final next = DocumentStatus.values[(current.index + 1) % DocumentStatus.values.length];
      _checklist[item] = next;
    });
  }

  String _statusLabel(VisaStatus status) {
    switch (status) {
      case VisaStatus.notStarted:
        return 'Not Started';
      case VisaStatus.inProgress:
        return 'In Progress';
      case VisaStatus.approved:
        return 'Approved';
    }
  }

  String _documentStatusLabel(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
    }
  }

  Color _documentStatusColor(DocumentStatus status, ThemeData theme) {
    switch (status) {
      case DocumentStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
      case DocumentStatus.uploaded:
        return AppTheme.primary;
      case DocumentStatus.verified:
        return Colors.green;
      case DocumentStatus.rejected:
        return Colors.redAccent;
    }
  }

  Widget _buildChecklistItem(String title) {
    final theme = Theme.of(context);
    final status = _checklist[title] ?? DocumentStatus.pending;

    return InkWell(
      onTap: () => _cycleItemStatus(title),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Symbols.check_circle,
              color: _documentStatusColor(status, theme),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              _documentStatusLabel(status),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _documentStatusColor(status, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visa & Immigration'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visa Status',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _statusLabel(_visaStatus),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _visaStatus == VisaStatus.approved
                    ? Colors.green
                    : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(height: 16),
            ..._checklist.keys.map((key) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildChecklistItem(key),
                )),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_visaStatus == VisaStatus.notStarted) {
                      _visaStatus = VisaStatus.inProgress;
                    } else if (_visaStatus == VisaStatus.inProgress) {
                      _visaStatus = VisaStatus.approved;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _visaStatus == VisaStatus.approved ? 'Visa Approved' : 'Start Visa Application',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  VisaImmigrationScreenResult(status: _visaStatus, checklist: _checklist),
                );
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
