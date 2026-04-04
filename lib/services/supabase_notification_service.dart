import 'package:flutter/foundation.dart';

import 'package:au_connect/services/supabase_client_provider.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.createdAt,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'announcement',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class NotificationService {
  static final _client = SupabaseClientProvider.client;

  static Future<List<AppNotification>> getMyNotifications() async {
    final uid = SupabaseClientProvider.currentUserId;
    if (uid == null) return [];
    try {
      final res = await _client.from('notifications').select().eq('recipient_id', uid).order('created_at', ascending: false);
      return (res as List).map((row) => AppNotification.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('getMyNotifications error: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  static Stream<List<AppNotification>> streamMyNotifications() {
    final uid = SupabaseClientProvider.currentUserId;
    if (uid == null) return const Stream.empty();
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => AppNotification.fromJson(Map<String, dynamic>.from(row))).toList());
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      debugPrint('markAsRead error: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}
