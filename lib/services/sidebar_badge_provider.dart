import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Holds live badge counts for the admin sidebar.
/// Subscribe once at the dashboard level; counts update via Supabase Realtime.
class SidebarBadgeProvider extends ChangeNotifier {
  static final _db = Supabase.instance.client;

  int applications  = 0;
  int students      = 0;
  int documents     = 0;
  int notifications = 0;
  int announcements = 0;

  final List<StreamSubscription> _subs = [];

  SidebarBadgeProvider() {
    _init();
  }

  Future<void> _init() async {
    await _fetchAll();
    _subscribeRealtime();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchApplications(),
      _fetchStudents(),
      _fetchDocuments(),
      _fetchNotifications(),
      _fetchAnnouncements(),
    ]);
    notifyListeners();
  }

  Future<void> _fetchApplications() async {
    try {
      final res = await _db.from('applications').select('id');
      applications = (res as List).length;
    } catch (_) {}
  }

  Future<void> _fetchStudents() async {
    try {
      final res = await _db.from('applications').select('id').eq('status', 'Approved');
      students = (res as List).length;
    } catch (_) {}
  }

  Future<void> _fetchDocuments() async {
    try {
      final res = await _db.from('documents').select('id').eq('status', 'Pending');
      documents = (res as List).length;
    } catch (_) {}
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await _db
          .from('notifications')
          .select('id')
          .eq('is_read', false)
          .eq('recipient_role', 'admin');
      notifications = (res as List).length;
    } catch (_) {}
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final res = await _db
          .from('announcements')
          .select('id')
          .inFilter('status', ['draft', 'scheduled']);
      announcements = (res as List).length;
    } catch (_) {}
  }

  void _subscribeRealtime() {
    // Applications stream
    _subs.add(
      _db.from('applications').stream(primaryKey: ['id']).listen((rows) {
        applications = rows.length;
        students = rows.where((r) => r['status'] == 'Approved').length;
        notifyListeners();
      }),
    );

    // Documents stream
    _subs.add(
      _db.from('documents').stream(primaryKey: ['id']).listen((rows) {
        documents = rows.where((r) => r['status'] == 'Pending').length;
        notifyListeners();
      }),
    );

    // Notifications stream
    _subs.add(
      _db.from('notifications').stream(primaryKey: ['id']).listen((rows) {
        notifications = rows
            .where((r) => r['is_read'] == false && r['recipient_role'] == 'admin')
            .length;
        notifyListeners();
      }),
    );

    // Announcements stream
    _subs.add(
      _db.from('announcements').stream(primaryKey: ['id']).listen((rows) {
        announcements = rows
            .where((r) => r['status'] == 'draft' || r['status'] == 'scheduled')
            .length;
        notifyListeners();
      }),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
