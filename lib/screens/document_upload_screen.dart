import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

enum DocumentUploadTask { transcript, english, passport, visa, overview }

enum DocumentUploadStatus { pending, uploaded, verified, rejected }

class DocumentUploadResult {
  final bool transcriptUploaded;
  final bool englishUploaded;
  final bool passportUploaded;
  final bool visaUploaded;

  const DocumentUploadResult({
    this.transcriptUploaded = false,
    this.englishUploaded = false,
    this.passportUploaded = false,
    this.visaUploaded = false,
  });

  DocumentUploadResult copyWith({
    bool? transcriptUploaded,
    bool? englishUploaded,
    bool? passportUploaded,
    bool? visaUploaded,
  }) {
    return DocumentUploadResult(
      transcriptUploaded: transcriptUploaded ?? this.transcriptUploaded,
      englishUploaded: englishUploaded ?? this.englishUploaded,
      passportUploaded: passportUploaded ?? this.passportUploaded,
      visaUploaded: visaUploaded ?? this.visaUploaded,
    );
  }
}

class DocumentUploadScreen extends StatefulWidget {
  final DocumentUploadTask task;
  final DocumentUploadResult? initialResult;

  const DocumentUploadScreen({
    super.key,
    required this.task,
    this.initialResult,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  late Map<DocumentUploadTask, DocumentUploadStatus> _status;

  @override
  void initState() {
    super.initState();
    _status = {
      DocumentUploadTask.transcript:
          widget.initialResult?.transcriptUploaded == true ? DocumentUploadStatus.uploaded : DocumentUploadStatus.pending,
      DocumentUploadTask.english:
          widget.initialResult?.englishUploaded == true ? DocumentUploadStatus.uploaded : DocumentUploadStatus.pending,
      DocumentUploadTask.passport:
          widget.initialResult?.passportUploaded == true ? DocumentUploadStatus.uploaded : DocumentUploadStatus.pending,
      DocumentUploadTask.visa:
          widget.initialResult?.visaUploaded == true ? DocumentUploadStatus.uploaded : DocumentUploadStatus.pending,
    };
  }

  void _cycleStatus(DocumentUploadTask task) {
    setState(() {
      final current = _status[task] ?? DocumentUploadStatus.pending;
      _status[task] =
          DocumentUploadStatus.values[(current.index + 1) % DocumentUploadStatus.values.length];
    });
  }

  bool get _allCompleted {
    return _status.values.every((s) => s == DocumentUploadStatus.uploaded || s == DocumentUploadStatus.verified);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Upload'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titleForTask(widget.task),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _subtitleForTask(widget.task),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: widget.task == DocumentUploadTask.overview
                  ? _buildOverviewList(theme)
                  : _buildSingleTaskSection(theme, widget.task),
            ),
            const SizedBox(height: 12),
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
                    onPressed: () => Navigator.pop(context, DocumentUploadResult(
                      transcriptUploaded: _status[DocumentUploadTask.transcript] == DocumentUploadStatus.uploaded ||
                          _status[DocumentUploadTask.transcript] == DocumentUploadStatus.verified,
                      englishUploaded: _status[DocumentUploadTask.english] == DocumentUploadStatus.uploaded ||
                          _status[DocumentUploadTask.english] == DocumentUploadStatus.verified,
                      passportUploaded: _status[DocumentUploadTask.passport] == DocumentUploadStatus.uploaded ||
                          _status[DocumentUploadTask.passport] == DocumentUploadStatus.verified,
                      visaUploaded: _status[DocumentUploadTask.visa] == DocumentUploadStatus.uploaded ||
                          _status[DocumentUploadTask.visa] == DocumentUploadStatus.verified,
                    )),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(_allCompleted ? 'All documents uploaded' : 'Mark Complete'),
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

  String _titleForTask(DocumentUploadTask task) {
    switch (task) {
      case DocumentUploadTask.transcript:
        return 'Upload your high school transcript.';
      case DocumentUploadTask.english:
        return 'Upload your English proficiency test scores.';
      case DocumentUploadTask.passport:
        return 'Upload your passport copy.';
      case DocumentUploadTask.visa:
        return 'Upload your visa documents.';
      case DocumentUploadTask.overview:
        return 'Upload required documents for international applicants.';
    }
  }

  String _subtitleForTask(DocumentUploadTask task) {
    switch (task) {
      case DocumentUploadTask.transcript:
        return 'This section lets you upload your transcript and related academic records.';
      case DocumentUploadTask.english:
        return 'This section lets you upload your English proficiency test scores.';
      case DocumentUploadTask.passport:
        return 'Submit your passport copy for immigration checks.';
      case DocumentUploadTask.visa:
        return 'Upload all documents required for student visa processing.';
      case DocumentUploadTask.overview:
        return 'Track the status of passport, visa, transcript, and English proficiency documents.';
    }
  }

  Widget _buildSingleTaskSection(ThemeData theme, DocumentUploadTask task) {
    final status = _status[task] ?? DocumentUploadStatus.pending;
    final statusLabel = _statusLabel(status);
    final statusColor = _statusColor(status, theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusTile(theme, statusLabel, statusColor),
        const SizedBox(height: 18),
        _buildActionButton(theme, 'Upload Document', () => _cycleStatus(task)),
        const SizedBox(height: 12),
        _buildActionButton(theme, 'Mark as Verified', () {
          setState(() {
            _status[task] = DocumentUploadStatus.verified;
          });
        }),
        const SizedBox(height: 12),
        _buildActionButton(theme, 'Mark as Rejected', () {
          setState(() {
            _status[task] = DocumentUploadStatus.rejected;
          });
        }),
      ],
    );
  }

  Widget _buildOverviewList(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.zero,
      children: DocumentUploadTask.values
          .where((task) => task != DocumentUploadTask.overview)
          .map((task) {
            final status = _status[task] ?? DocumentUploadStatus.pending;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildDocumentRow(task, status, theme),
            );
          })
          .toList(),
    );
  }

  Widget _buildDocumentRow(DocumentUploadTask task, DocumentUploadStatus status, ThemeData theme) {
    final label = _labelForTask(task);
    final color = _statusColor(status, theme);

    return InkWell(
      onTap: () => _cycleStatus(task),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(Symbols.upload_file, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_statusLabel(status), style: theme.textTheme.bodySmall?.copyWith(color: color)),
                ],
              ),
            ),
            Icon(Symbols.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _labelForTask(DocumentUploadTask task) {
    switch (task) {
      case DocumentUploadTask.transcript:
        return 'High School Transcript';
      case DocumentUploadTask.english:
        return 'English Test (IELTS/TOEFL)';
      case DocumentUploadTask.passport:
        return 'Passport Copy';
      case DocumentUploadTask.visa:
        return 'Visa Documents';
      case DocumentUploadTask.overview:
        return '';
    }
  }

  String _statusLabel(DocumentUploadStatus status) {
    switch (status) {
      case DocumentUploadStatus.pending:
        return 'Pending';
      case DocumentUploadStatus.uploaded:
        return 'Uploaded';
      case DocumentUploadStatus.verified:
        return 'Verified';
      case DocumentUploadStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor(DocumentUploadStatus status, ThemeData theme) {
    switch (status) {
      case DocumentUploadStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
      case DocumentUploadStatus.uploaded:
        return AppTheme.primary;
      case DocumentUploadStatus.verified:
        return Colors.green;
      case DocumentUploadStatus.rejected:
        return Colors.redAccent;
    }
  }

  Widget _buildStatusTile(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(Symbols.check_circle, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: AppTheme.primary,
        ),
        child: Text(label),
      ),
    );
  }
}
