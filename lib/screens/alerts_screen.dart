import 'package:flutter/material.dart';
import 'package:au_connect/services/notification_service.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final NotificationService _notificationService = NotificationService();
  AlertType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearDialog(),
            tooltip: 'Clear all alerts',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildAlertsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedFilter == null,
            onSelected: (selected) {
              setState(() => _selectedFilter = null);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Deadlines'),
            selected: _selectedFilter == AlertType.deadline,
            onSelected: (selected) {
              setState(() => _selectedFilter = AlertType.deadline);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Grades'),
            selected: _selectedFilter == AlertType.gradePosted,
            onSelected: (selected) {
              setState(() => _selectedFilter = AlertType.gradePosted);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Announcements'),
            selected: _selectedFilter == AlertType.announcement,
            onSelected: (selected) {
              setState(() => _selectedFilter = AlertType.announcement);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    List<Alert> alerts = _selectedFilter == null
        ? _notificationService.getAlerts()
        : _notificationService.getAlertsByType(_selectedFilter!);

    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No alerts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertTile(alert);
      },
    );
  }

  Widget _buildAlertTile(Alert alert) {
    final icon = _getAlertIcon(alert.type);
    final color = _getAlertColor(alert.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          alert.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(alert.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy HH:mm').format(alert.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Mark as read'),
              onTap: () => _notificationService.markAsRead(alert.id),
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () => _notificationService.deleteAlert(alert.id),
            ),
          ],
        ),
        onTap: () => _showAlertDetail(alert),
      ),
    );
  }

  void _showAlertDetail(Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alert.message),
              const SizedBox(height: 16),
              Text(
                DateFormat('EEEE, MMMM d, yyyy HH:mm')
                    .format(alert.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (alert.dueDate != null) ...[
                const SizedBox(height: 16),
                Text('Due: ${DateFormat('MMMM d, yyyy').format(alert.dueDate!)}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              _notificationService.deleteAlert(alert.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all alerts?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _notificationService.clearAllAlerts();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.deadline:
        return Icons.schedule;
      case AlertType.gradePosted:
        return Icons.assignment_turned_in;
      case AlertType.announcement:
        return Icons.notifications;
    }
  }

  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.deadline:
        return Colors.orange;
      case AlertType.gradePosted:
        return Colors.green;
      case AlertType.announcement:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
