import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class TransferDocumentsScreen extends StatelessWidget {
  final int initialUploadedDocuments;
  final int totalDocuments;

  const TransferDocumentsScreen({
    super.key,
    this.initialUploadedDocuments = 2,
    this.totalDocuments = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required Documents',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDocumentRow(context, 'Transcripts', initialUploadedDocuments >= 1, () => _uploadDocument(context, 'Transcripts')),
              const SizedBox(height: 12),
              _buildDocumentRow(context, 'Course Outlines / Syllabi', initialUploadedDocuments >= 2, () => _uploadDocument(context, 'Course Outlines / Syllabi')),
              const SizedBox(height: 12),
              _buildDocumentRow(context, 'Recommendation Letters', initialUploadedDocuments >= 3, () => _uploadDocument(context, 'Recommendation Letters')),
              const SizedBox(height: 12),
              _buildDocumentRow(context, 'Additional Documents', initialUploadedDocuments >= 4, () => _uploadDocument(context, 'Additional Documents')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, String name, bool isUploaded, VoidCallback onUpload) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Symbols.upload_file, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUploaded ? 'Uploaded' : 'Not uploaded',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isUploaded ? null : onUpload,
              child: Text(isUploaded ? 'View' : 'Upload'),
            ),
          ],
        ),
      ),
    );
  }

  void _uploadDocument(BuildContext context, String documentName) {
    // Simulate upload process
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$documentName uploaded successfully!')),
    );
    // Return updated count to dashboard
    Navigator.pop(context, initialUploadedDocuments + 1);
  }
}
