import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AlertType { deadline, gradePosted, announcement }

class Alert {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  Alert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.dueDate,
    this.isRead = false,
    this.metadata,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      isRead: json['is_read'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'is_read': isRead,
      'metadata': metadata,
    };
  }
}

class NotificationService {
  static const String _baseUrl = 'https://your-api.com';
  static final NotificationService _instance = NotificationService._internal();
  
  late SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  List<Alert> _alerts = [];

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLocalAlerts();
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // Request notification permissions
    if (identical(defaultTargetPlatform, TargetPlatform.iOS)) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _handleRemoteNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleRemoteNotification(message);
    });
  }

  void _handleRemoteNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    final alertType = _parseAlertType(message.data['type'] ?? 'announcement');

    final alert = Alert(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: alertType,
      title: title,
      message: body,
      createdAt: DateTime.now(),
      metadata: message.data,
    );

    _saveAlert(alert);
    _showLocalNotification(alert);
  }

  AlertType _parseAlertType(String type) {
    switch (type) {
      case 'deadline':
        return AlertType.deadline;
      case 'grade_posted':
        return AlertType.gradePosted;
      default:
        return AlertType.announcement;
    }
  }

  /// Send deadline reminder notification
  Future<void> sendDeadlineReminder({
    required String applicationId,
    required String applicationName,
    required DateTime deadline,
    required String recipientId,
  }) async {
    try {
      final alert = Alert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AlertType.deadline,
        title: 'Deadline Reminder',
        message: 'Deadline for $applicationName is on ${_formatDate(deadline)}',
        createdAt: DateTime.now(),
        dueDate: deadline,
        metadata: {
          'application_id': applicationId,
          'application_name': applicationName,
          'recipient_id': recipientId,
        },
      );

      await _saveAlert(alert);
      await _showLocalNotification(alert);
      await _sendRemoteNotification(alert, recipientId);
    } catch (e) {
      print('Error sending deadline reminder: $e');
    }
  }

  /// Send grade posted notification
  Future<void> sendGradePostedAlert({
    required String courseId,
    required String courseName,
    required double grade,
    required String recipientId,
  }) async {
    try {
      final alert = Alert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AlertType.gradePosted,
        title: 'Grade Posted',
        message: 'Your grade for $courseName has been posted: $grade',
        createdAt: DateTime.now(),
        metadata: {
          'course_id': courseId,
          'course_name': courseName,
          'grade': grade,
          'recipient_id': recipientId,
        },
      );

      await _saveAlert(alert);
      await _showLocalNotification(alert);
      await _sendRemoteNotification(alert, recipientId);
    } catch (e) {
      print('Error sending grade alert: $e');
    }
  }

  /// Send announcement notification
  Future<void> sendAnnouncementAlert({
    required String announcementId,
    required String title,
    required String content,
    required String recipientId,
  }) async {
    try {
      final alert = Alert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AlertType.announcement,
        title: title,
        message: content,
        createdAt: DateTime.now(),
        metadata: {
          'announcement_id': announcementId,
          'recipient_id': recipientId,
        },
      );

      await _saveAlert(alert);
      await _showLocalNotification(alert);
      await _sendRemoteNotification(alert, recipientId);
    } catch (e) {
      print('Error sending announcement: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(Alert alert) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'alert_channel_id',
        'Alerts',
        channelDescription: 'Channel for alert notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails();

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        alert.id.hashCode,
        alert.title,
        alert.message,
        notificationDetails,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  /// Save alert locally
  Future<void> _saveAlert(Alert alert) async {
    _alerts.add(alert);
    final alertsList = _alerts.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList('alerts', alertsList);
  }

  /// Load alerts from local storage
  Future<void> _loadLocalAlerts() async {
    try {
      final alertsList = _prefs.getStringList('alerts') ?? [];
      _alerts = alertsList
          .map((alertJson) => Alert.fromJson(jsonDecode(alertJson)))
          .toList();
    } catch (e) {
      print('Error loading alerts: $e');
    }
  }

  /// Send notification to remote server
  Future<void> _sendRemoteNotification(Alert alert, String recipientId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...alert.toJson(),
          'recipient_id': recipientId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('Failed to send remote notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending remote notification: $e');
    }
  }

  /// Get all alerts
  List<Alert> getAlerts() => List.unmodifiable(_alerts);

  /// Get unread alerts
  List<Alert> getUnreadAlerts() => _alerts.where((a) => !a.isRead).toList();

  /// Get alerts by type
  List<Alert> getAlertsByType(AlertType type) =>
      _alerts.where((a) => a.type == type).toList();

  /// Mark alert as read
  Future<void> markAsRead(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = Alert(
        id: _alerts[index].id,
        type: _alerts[index].type,
        title: _alerts[index].title,
        message: _alerts[index].message,
        createdAt: _alerts[index].createdAt,
        dueDate: _alerts[index].dueDate,
        isRead: true,
        metadata: _alerts[index].metadata,
      );
      await _loadLocalAlerts();
    }
  }

  /// Delete alert
  Future<void> deleteAlert(String alertId) async {
    _alerts.removeWhere((a) => a.id == alertId);
    final alertsList = _alerts.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList('alerts', alertsList);
  }

  /// Clear all alerts
  Future<void> clearAllAlerts() async {
    _alerts.clear();
    await _prefs.setStringList('alerts', []);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
