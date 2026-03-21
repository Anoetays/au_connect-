import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class TransferNotificationsScreen extends StatefulWidget {
  final List<String> initialNotifications;

  const TransferNotificationsScreen({
    super.key,
    required this.initialNotifications,
  });

  @override
  State<TransferNotificationsScreen> createState() => _TransferNotificationsScreenState();
}

class _TransferNotificationsScreenState extends State<TransferNotificationsScreen> {
  late List<String> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(widget.initialNotifications);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add),
            onPressed: _addNotification,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(24.0),
          itemCount: _notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Symbols.notifications, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _notifications[index],
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Just now',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Symbols.delete, color: theme.colorScheme.onSurfaceVariant),
                      onPressed: () => _deleteNotification(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _addNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notification'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Enter notification message'),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _notifications.insert(0, value);
              });
              Navigator.pop(context);
              Navigator.pop(context, _notifications);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Could add logic to get text from controller
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    Navigator.pop(context, _notifications);
  }
}
