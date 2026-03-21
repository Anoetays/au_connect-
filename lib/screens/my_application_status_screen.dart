import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/models/application_status.dart';

class MyApplicationStatusScreen extends StatefulWidget {
  const MyApplicationStatusScreen({super.key});

  @override
  State<MyApplicationStatusScreen> createState() => _MyApplicationStatusScreenState();
}

class _MyApplicationStatusScreenState extends State<MyApplicationStatusScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStatus = ApplicationData.currentStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Application Status'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Progress',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildCurrentStatusCard(currentStatus),
            const SizedBox(height: 20),
            _buildProgressBar(currentStatus),
            const SizedBox(height: 20),
            if (currentStatus == ApplicationStatus.approved || currentStatus == ApplicationStatus.rejected)
              _buildStatusMessage(currentStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(ApplicationStatus status) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(status.icon, color: status.color, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.displayName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ApplicationStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: status.progressValue / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(status.color),
        ),
        const SizedBox(height: 4),
        Text(
          '${status.progressValue}% Complete',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(ApplicationStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.description,
              style: TextStyle(
                color: status.color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}