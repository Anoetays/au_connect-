import 'package:flutter/material.dart';
import 'package:au_connect/services/tracking_service.dart';
import 'package:intl/intl.dart';

class ApplicationTrackingWidget extends StatefulWidget {
  final String applicationId;

  const ApplicationTrackingWidget({
    required this.applicationId,
    Key? key,
  }) : super(key: key);

  @override
  State<ApplicationTrackingWidget> createState() =>
      _ApplicationTrackingWidgetState();
}

class _ApplicationTrackingWidgetState extends State<ApplicationTrackingWidget> {
  final TrackingService _trackingService = TrackingService();
  late Stream<ApplicationTrackingData> _trackingStream;

  @override
  void initState() {
    super.initState();
    _trackingStream = _trackingService.getTrackingStream(widget.applicationId);
    _trackingService.fetchApplicationStatus(widget.applicationId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ApplicationTrackingData>(
      stream: _trackingStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Unable to load tracking data'));
        }

        final trackingData = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusCard(trackingData),
              const SizedBox(height: 16),
              _buildProgressIndicator(trackingData),
              const SizedBox(height: 16),
              _buildDocumentVerification(trackingData),
              const SizedBox(height: 16),
              _buildTimeline(trackingData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(ApplicationTrackingData data) {
    final statusColor = TrackingService.getStatusColor(data.status);
    final statusLabel = TrackingService.getStatusLabel(data.status);
    final daysLeft = _trackingService.getDaysUntilDecision(data);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.applicationName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (daysLeft != null)
              Text(
                'Est. Decision: ${daysLeft > 0 ? 'in $daysLeft days' : 'Soon'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ApplicationTrackingData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Application Progress',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: data.progressPercentage / 100,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${data.progressPercentage.toStringAsFixed(0)}% Complete',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDocumentVerification(ApplicationTrackingData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Verification',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...data.documents.map((doc) => _buildDocumentTile(doc)),
      ],
    );
  }

  Widget _buildDocumentTile(DocumentVerification doc) {
    final statusColor = _getDocumentStatusColor(doc.status);
    final statusIcon = _getDocumentStatusIcon(doc.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.documentName),
                if (doc.rejectionReason != null)
                  Text(
                    'Reason: ${doc.rejectionReason}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            _getDocumentStatusLabel(doc.status),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ApplicationTrackingData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Update History',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...data.updates.asMap().entries.map((entry) {
          final isLast = entry.key == data.updates.length - 1;
          return _buildTimelineItem(entry.value, !isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(TrackingUpdate update, bool showLine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              if (showLine)
                Container(
                  width: 2,
                  height: 24,
                  color: Colors.blue[200],
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.status,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(update.description),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy HH:mm').format(update.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDocumentStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return Colors.green;
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.resubmitRequired:
        return Colors.orange;
      case DocumentStatus.pending:
        return Colors.blue;
    }
  }

  IconData _getDocumentStatusIcon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return Icons.check_circle;
      case DocumentStatus.rejected:
        return Icons.cancel;
      case DocumentStatus.resubmitRequired:
        return Icons.warning;
      case DocumentStatus.pending:
        return Icons.schedule;
    }
  }

  String _getDocumentStatusLabel(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.resubmitRequired:
        return 'Resubmit';
      case DocumentStatus.pending:
        return 'Pending';
    }
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }
}
