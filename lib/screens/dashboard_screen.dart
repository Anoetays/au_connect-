import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:au_connect/models/application.dart';
import 'package:au_connect/services/application_service.dart';
import 'package:au_connect/services/supabase_notification_service.dart';
import 'package:au_connect/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _RealtimePanel<Application>(
                title: 'My Applications',
                stream: ApplicationService.streamMyApplications(),
                itemBuilder: (context, app) => ListTile(
                  title: Text(app.programme.isEmpty ? 'Draft application' : app.programme),
                  subtitle: Text('${app.status} • ${app.faculty}'),
                  trailing: Icon(
                    app.isSubmitted ? Icons.check_circle : Icons.edit,
                    color: app.isSubmitted ? Colors.green : AppTheme.primaryDark,
                  ),
                ),
                emptyText: 'No application data yet.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _RealtimePanel<AppNotification>(
                title: 'Notifications',
                stream: NotificationService.streamMyNotifications(),
                itemBuilder: (context, notification) => ListTile(
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                  trailing: notification.isRead
                      ? const Icon(Icons.mark_email_read, color: Colors.green)
                      : const Icon(Icons.mark_email_unread_outlined),
                ),
                emptyText: 'No notifications yet.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealtimePanel<T> extends StatelessWidget {
  const _RealtimePanel({
    required this.title,
    required this.stream,
    required this.itemBuilder,
    required this.emptyText,
  });

  final String title;
  final Stream<List<T>> stream;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<T>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return Center(child: Text(emptyText));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => itemBuilder(context, items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
