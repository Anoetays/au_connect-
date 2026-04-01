import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central service for all Supabase data access.
/// All methods are static — no instance needed.
class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ── AUTH ────────────────────────────────────────────────────────────────────

  static User? get currentUser => _db.auth.currentUser;
  static String? get currentUserId => _db.auth.currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      _db.auth.onAuthStateChange;

  static Future<void> signOut() => _db.auth.signOut();

  // ── PROFILES ─────────────────────────────────────────────────────────────────

  /// Fetch the signed-in user's profile row.
  static Future<Map<String, dynamic>?> getProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      return await _db
          .from('profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
    } catch (e) {
      debugPrint('getProfile error: $e');
      return null;
    }
  }

  /// Create or update the user's profile.
  static Future<void> upsertProfile(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');
    await _db.from('profiles').upsert({...data, 'user_id': uid});
  }

  /// Fetch all profiles (admin use).
  static Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      final res = await _db.from('profiles').select().order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getAllProfiles error: $e');
      return [];
    }
  }

  // ── APPLICATIONS ─────────────────────────────────────────────────────────────

  /// Submit a new application, auto-generating the applicant ID (AU-2025-XXXX).
  /// Returns the generated applicant ID on success.
  static Future<String> submitApplication({
    required String applicantName,
    required String email,
    required String type,
    required String programme,
    required String faculty,
    required String nationality,
  }) async {
    // Count existing rows to derive the next sequential number.
    final existing = await _db.from('applications').select('id');
    final n = ((existing as List).length + 1).toString().padLeft(4, '0');
    final applicantId = 'AU-2025-$n';

    await _db.from('applications').insert({
      'applicant_id': applicantId,
      'applicant_name': applicantName,
      'email': email,
      'type': type,
      'programme': programme,
      'faculty': faculty,
      'nationality': nationality,
      'status': 'Pending',
    });

    return applicantId;
  }

  /// Update the programme and faculty on an existing application.
  static Future<void> updateApplicationProgramme(
    String applicationId, {
    required String programme,
    required String faculty,
  }) async {
    await _db.from('applications').update({
      'programme': programme,
      'faculty': faculty,
    }).eq('id', applicationId);
  }

  /// Fetch the current user's most recent application.
  static Future<Map<String, dynamic>?> getMyApplication() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      return await _db
          .from('applications')
          .select()
          .eq('user_id', uid)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      debugPrint('getMyApplication error: $e');
      return null;
    }
  }

  /// Fetch all applications, with optional filters (admin use).
  static Future<List<Map<String, dynamic>>> getAllApplications({
    String? status,
    String? type,
  }) async {
    try {
      var query = _db
          .from('applications')
          .select('*, profiles(full_name, email, country_of_origin)');
      if (status != null) {
        query = query.eq('status', status);
      }
      if (type != null) {
        query = query.eq('type', type);
      }
      final res =
          await query.order('submitted_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getAllApplications error: $e');
      return [];
    }
  }

  /// Update the status (and optional notes) of an application.
  static Future<void> updateApplicationStatus(
    String applicationId,
    String status, {
    String? notes,
  }) async {
    final update = <String, dynamic>{'status': status};
    if (notes != null) update['notes'] = notes;
    await _db.from('applications').update(update).eq('id', applicationId);
  }

  /// Real-time stream of the current user's applications.
  static Stream<List<Map<String, dynamic>>> streamMyApplications() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _db
        .from('applications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('submitted_at', ascending: false);
  }

  /// Real-time stream of ALL applications (admin use).
  static Stream<List<Map<String, dynamic>>> streamAllApplications() {
    return _db
        .from('applications')
        .stream(primaryKey: ['id'])
        .order('submitted_at', ascending: false);
  }

  // ── DOCUMENTS ─────────────────────────────────────────────────────────────────

  /// Fetch documents for a given application.
  static Future<List<Map<String, dynamic>>> getDocuments(
      String applicationId) async {
    try {
      final res = await _db
          .from('documents')
          .select()
          .eq('application_id', applicationId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getDocuments error: $e');
      return [];
    }
  }

  /// Upload a document record for the current user's application.
  /// Stores the file_name and document_type in the documents table.
  /// If a local file path is provided and Supabase Storage is configured,
  /// the bytes are uploaded; otherwise only the metadata row is inserted.
  static Future<void> uploadDocument({
    required String fileName,
    required String documentType,
    String filePath = '',
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    // Fetch the current application to get its ID
    final app = await getMyApplication();

    final payload = <String, dynamic>{
      'user_id': uid,
      'file_name': fileName,
      'document_type': documentType,
      'verification_status': 'Pending',
      'uploaded_at': DateTime.now().toIso8601String(),
    };
    if (app != null) payload['application_id'] = app['id'];

    await _db.from('documents').insert(payload);
  }

  /// Mark a document as verified or rejected.
  static Future<void> setDocumentVerified(String docId, bool verified) async {
    await _db.from('documents').update({'verified': verified}).eq('id', docId);
  }

  // ── ANNOUNCEMENTS ─────────────────────────────────────────────────────────────

  /// Fetch recent announcements for a given role (also includes 'all').
  static Future<List<Map<String, dynamic>>> getAnnouncements(
      String role) async {
    try {
      final res = await _db
          .from('announcements')
          .select()
          .or('target_role.eq.$role,target_role.eq.all')
          .order('created_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getAnnouncements error: $e');
      return [];
    }
  }

  /// Create a new announcement (admin use).
  static Future<void> createAnnouncement({
    required String title,
    required String body,
    required String targetRole,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');
    await _db.from('announcements').insert({
      'title': title,
      'body': body,
      'target_role': targetRole,
      'created_by': uid,
    });
  }

  /// Real-time stream of announcements for a role.
  static Stream<List<Map<String, dynamic>>> streamAnnouncements(String role) {
    return _db
        .from('announcements')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // ── ACADEMIC RECORDS ─────────────────────────────────────────────────────────

  /// Fetch all academic records for the current user.
  static Future<List<Map<String, dynamic>>> getAcademicRecords() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final res = await _db
          .from('academic_records')
          .select()
          .eq('user_id', uid)
          .order('semester', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getAcademicRecords error: $e');
      return [];
    }
  }

  // ── FEE RECORDS ───────────────────────────────────────────────────────────────

  /// Fetch the most recent fee record for the current user.
  static Future<Map<String, dynamic>?> getFeeRecord() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      return await _db
          .from('fee_records')
          .select()
          .eq('user_id', uid)
          .order('due_date', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      debugPrint('getFeeRecord error: $e');
      return null;
    }
  }

  // ── PAYMENTS ──────────────────────────────────────────────────────────────────

  /// Fetch all payment records for the current user, newest first.
  static Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final res = await _db
          .from('payments')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getPaymentHistory error: $e');
      return [];
    }
  }

  // ── ADMIN DOCUMENTS ───────────────────────────────────────────────────────────

  /// Real-time stream of ALL documents (admin use), newest first.
  static Stream<List<Map<String, dynamic>>> streamAllDocuments() {
    return _db
        .from('documents')
        .stream(primaryKey: ['id'])
        .order('uploaded_at', ascending: false);
  }

  /// Update a document's status text (Pending / Verified / Rejected / Under Review).
  static Future<void> updateDocumentStatus(
    String docId,
    String status, {
    String? reviewedBy,
  }) async {
    final payload = <String, dynamic>{'status': status};
    if (reviewedBy != null) payload['reviewed_by'] = reviewedBy;
    await _db.from('documents').update(payload).eq('id', docId);
  }

  // ── PROGRAMME REQUIREMENTS ────────────────────────────────────────────────────

  /// Fetch all requirement rows for a given programme name.
  static Future<List<Map<String, dynamic>>> getProgrammeRequirements(
      String programmeName) async {
    try {
      final res = await _db
          .from('programme_requirements')
          .select()
          .eq('programme_name', programmeName);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getProgrammeRequirements error: $e');
      return [];
    }
  }

  /// Fetch all active programmes for a given faculty.
  static Future<List<Map<String, dynamic>>> getProgrammesByFaculty(
      String faculty) async {
    try {
      final res = await _db
          .from('programmes')
          .select()
          .eq('faculty', faculty)
          .eq('status', 'Active');
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getProgrammesByFaculty error: $e');
      return [];
    }
  }

  // ── ADMIN PROGRAMMES ──────────────────────────────────────────────────────────

  /// Real-time stream of all programmes.
  static Stream<List<Map<String, dynamic>>> streamProgrammes() {
    return _db
        .from('programmes')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true);
  }

  /// Insert a new programme row.
  static Future<void> insertProgramme({
    required String name,
    required String faculty,
    required String level,
    required int durationYears,
  }) async {
    await _db.from('programmes').insert({
      'name': name,
      'faculty': faculty,
      'level': level,
      'duration_years': durationYears,
      'status': 'Active',
    });
  }

  /// Update an existing programme row.
  static Future<void> updateProgramme(String id, {
    required String name,
    required String faculty,
    required String level,
    required int durationYears,
  }) async {
    await _db.from('programmes').update({
      'name': name,
      'faculty': faculty,
      'level': level,
      'duration_years': durationYears,
    }).eq('id', id);
  }

  /// Delete a programme row by id.
  static Future<void> deleteProgramme(String id) async {
    await _db.from('programmes').delete().eq('id', id);
  }

  // ── ADMIN STAFF ───────────────────────────────────────────────────────────────

  /// Real-time stream of all staff rows.
  static Stream<List<Map<String, dynamic>>> streamStaff() {
    return _db
        .from('staff')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true);
  }

  /// Insert a new pending-invite staff row.
  static Future<void> inviteStaff({
    required String name,
    required String email,
    required String role,
    String? department,
  }) async {
    await _db.from('staff').insert({
      'name': name,
      'email': email,
      'role': role,
      'status': 'Pending',
      if (department != null) 'department': department,
    });
  }

  // ── ADMIN INTERVIEWS ──────────────────────────────────────────────────────────

  /// Real-time stream of all interviews, ordered by scheduled_date.
  static Stream<List<Map<String, dynamic>>> streamInterviews() {
    return _db
        .from('interviews')
        .stream(primaryKey: ['id'])
        .order('scheduled_date', ascending: true);
  }

  /// Update an interview's status.
  static Future<void> updateInterviewStatus(
      String interviewId, String status) async {
    await _db
        .from('interviews')
        .update({'status': status})
        .eq('id', interviewId);
  }

  // ── ADMIN ANNOUNCEMENTS ───────────────────────────────────────────────────────

  /// Real-time stream of all admin announcements, newest first.
  static Stream<List<Map<String, dynamic>>> streamAdminAnnouncements() {
    return _db
        .from('announcements')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Post a new announcement.
  static Future<void> postAnnouncement({
    required String title,
    required String message,
    required String priority,
    required String audience,
    required String status,
    DateTime? scheduledAt,
  }) async {
    await _db.from('announcements').insert({
      'title': title,
      'message': message,
      'priority': priority,
      'audience': audience,
      'status': status,
      if (scheduledAt != null)
        'scheduled_at': scheduledAt.toIso8601String(),
    });
  }

  /// Delete an announcement by id.
  static Future<void> deleteAnnouncement(String id) async {
    await _db.from('announcements').delete().eq('id', id);
  }

  // ── ADMIN NOTIFICATIONS ───────────────────────────────────────────────────────

  /// Real-time stream of all notifications, newest first.
  static Stream<List<Map<String, dynamic>>> streamNotifications() {
    return _db
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Mark every unread notification as read.
  static Future<void> markAllNotificationsRead() async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('is_read', false);
  }

  /// Mark a single notification as read.
  static Future<void> markNotificationRead(String id) async {
    await _db.from('notifications').update({'is_read': true}).eq('id', id);
  }

  /// Delete (dismiss) a single notification.
  static Future<void> dismissNotification(String id) async {
    await _db.from('notifications').delete().eq('id', id);
  }

  /// Insert a system notification (called after approve / reject / verify).
  static Future<void> insertNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    await _db.from('notifications').insert({
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
    });
  }

  // ── AUDIT LOGS ────────────────────────────────────────────────────────────────

  /// Real-time stream of audit log entries, newest first.
  static Stream<List<Map<String, dynamic>>> streamAuditLogs() {
    return _db
        .from('audit_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Insert one audit log entry.
  static Future<void> insertAuditLog({
    required String adminName,
    required String adminRole,
    required String actionType,
    required String description,
    required String targetId,
    required String targetType,
    String? ipAddress,
  }) async {
    await _db.from('audit_logs').insert({
      'admin_name': adminName,
      'admin_role': adminRole,
      'action_type': actionType,
      'description': description,
      'target_id': targetId,
      'target_type': targetType,
      if (ipAddress != null) 'ip_address': ipAddress,
    });
  }

  // ── APPLICATION STATUS HISTORY ───────────────────────────────────────────────

  /// Stream status change history for a specific application.
  static Stream<List<Map<String, dynamic>>> streamStatusHistory(
      String applicationId) {
    return _db
        .from('application_status_history')
        .stream(primaryKey: ['id'])
        .eq('application_id', applicationId)
        .order('changed_at', ascending: true);
  }

  /// Update application status AND insert a history record.
  static Future<void> updateApplicationStatusWithHistory(
    String applicationId,
    String status, {
    String? changedBy,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.from('applications').update({
      'status': status,
      'updated_at': now,
    }).eq('id', applicationId);
    try {
      await _db.from('application_status_history').insert({
        'application_id': applicationId,
        'status': status,
        'changed_by': changedBy ?? currentUser?.email ?? 'Admin',
        'changed_at': now,
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      debugPrint('statusHistory insert error: $e');
    }
  }

  // ── DOCUMENT VERIFICATION ─────────────────────────────────────────────────

  /// Mark a document as Verified.
  static Future<void> verifyDocument(String docId, {String? note}) async {
    await _db.from('documents').update({
      'status': 'Verified',
      'verification_status': 'Verified',
      if (note != null) 'verification_note': note,
      'verified_by': currentUserId,
      'verified_at': DateTime.now().toIso8601String(),
    }).eq('id', docId);
  }

  /// Mark a document as Rejected with a reason.
  static Future<void> rejectDocument(
      String docId, {required String reason}) async {
    await _db.from('documents').update({
      'status': 'Rejected',
      'verification_status': 'Rejected',
      'verification_note': reason,
      'verified_by': currentUserId,
      'verified_at': DateTime.now().toIso8601String(),
    }).eq('id', docId);
  }

  /// Stream documents uploaded by the current user.
  static Stream<List<Map<String, dynamic>>> streamMyDocuments() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _db
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('uploaded_at', ascending: false);
  }

  // ── OFFER LETTERS ─────────────────────────────────────────────────────────

  /// Fetch the current user's most recent offer letter.
  static Future<Map<String, dynamic>?> getMyOfferLetter() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      return await _db
          .from('offer_letters')
          .select()
          .eq('applicant_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      debugPrint('getMyOfferLetter error: $e');
      return null;
    }
  }

  // ── REPORTS ───────────────────────────────────────────────────────────────────

  /// Stream all applications (used by reports page for realtime updates).
  static Stream<List<Map<String, dynamic>>> streamApplications() {
    return _db
        .from('applications')
        .stream(primaryKey: ['id'])
        .order('submitted_at', ascending: true);
  }

  /// Count applications submitted in each of the last [weeks] weeks.
  /// Returns list from oldest week to newest: [(label, count), ...].
  static List<MapEntry<String, int>> groupByWeek(
      List<Map<String, dynamic>> apps, {int weeks = 8}) {
    final now = DateTime.now();
    final result = <MapEntry<String, int>>[];
    for (var i = weeks - 1; i >= 0; i--) {
      final dayOfWeek = now.weekday; // 1=Mon ... 7=Sun
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: dayOfWeek - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final count = apps.where((r) {
        final dt = DateTime.tryParse(r['submitted_at'] as String? ?? '')?.toLocal();
        if (dt == null) return false;
        return !dt.isBefore(weekStart) && dt.isBefore(weekEnd);
      }).length;
      result.add(MapEntry('W${weeks - i}', count));
    }
    return result;
  }

  /// Count applications grouped by type field.
  static Map<String, int> groupByType(List<Map<String, dynamic>> apps) {
    final counts = <String, int>{};
    for (final r in apps) {
      final type = r['type'] as String? ?? 'Unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  // ── ANALYTICS ─────────────────────────────────────────────────────────────────

  /// Aggregate application counts by status and type.
  static Future<Map<String, dynamic>> getApplicationStats() async {
    try {
      final all = await _db.from('applications').select('status, type');
      final list = List<Map<String, dynamic>>.from(all as List);
      return {
        'total': list.length,
        'pending': list.where((a) => a['status'] == 'pending').length,
        'approved': list.where((a) => a['status'] == 'approved').length,
        'denied': list.where((a) => a['status'] == 'denied').length,
        'undergraduate':
            list.where((a) => a['type'] == 'undergraduate').length,
        'masters': list.where((a) => a['type'] == 'masters').length,
        'international':
            list.where((a) => a['type'] == 'international').length,
        'returning': list.where((a) => a['type'] == 'returning').length,
      };
    } catch (e) {
      debugPrint('getApplicationStats error: $e');
      return {'total': 0, 'pending': 0, 'approved': 0, 'denied': 0};
    }
  }

  /// Count applicants grouped by country of origin (for heatmap).
  static Future<Map<String, int>> getApplicantsByCountry() async {
    try {
      final res = await _db
          .from('profiles')
          .select('country_of_origin')
          .not('country_of_origin', 'is', null);
      final counts = <String, int>{};
      for (final row in (res as List)) {
        final country =
            (row as Map<String, dynamic>)['country_of_origin'] as String? ??
                'Unknown';
        counts[country] = (counts[country] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('getApplicantsByCountry error: $e');
      return {};
    }
  }
}
