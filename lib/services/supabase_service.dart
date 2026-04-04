import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central service for all Supabase data access.
/// All methods are static — no instance needed.
class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;
  static final Random _random = Random.secure();

  static bool _isMissingDocumentsTable(Object error) {
    if (error is! PostgrestException) return false;
    final msg = error.message.toLowerCase();
    return error.code == 'PGRST205' && msg.contains('public.documents');
  }

  static String _generateApplicantId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final token = List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    return 'AU-$timestamp-$token';
  }

  // ── AUTH ────────────────────────────────────────────────────────────────────

  static User? get currentUser => _db.auth.currentUser;
  static String? get currentUserId => _db.auth.currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      _db.auth.onAuthStateChange;

  static Future<void> signOut() async {
    final userId = _db.auth.currentUser?.id ?? 'none';
    debugPrint('Signing out user ID: $userId');
    _db.removeAllChannels();
    await _db.auth.signOut();
    debugPrint('Signed out user ID: $userId');
  }

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
    String? phone,
    String? source,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final applicantId = _generateApplicantId();
    final now = DateTime.now().toIso8601String();

    final payload = <String, dynamic>{
      'application_code': applicantId,
      'applicant_name': applicantName,
      'email': email,
      'type': type,
      'programme': programme,
      'faculty': faculty,
      'nationality': nationality,
      'status': 'Pending',
      'user_id': uid,
      'submitted_at': now,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (source != null && source.isNotEmpty) 'source': source,
    };

    await _db.from('applications').insert(payload);

    return applicantId;
  }

  /// Finalize the current user's application — creates one if it doesn't exist
  /// yet, or promotes an existing draft to Pending.  Returns the applicant ID.
  static Future<String> finalizeSubmission() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final profile = await getProfile();
    final name        = profile?['full_name']         as String? ?? '';
    final email       = profile?['email']             as String?
                     ?? currentUser?.email             ?? '';
    final nationality = profile?['country_of_origin'] as String? ?? '';
    final type        = profile?['applicant_type']    as String? ?? 'Local';

    // Check for an existing application row for this user
    final existing = await getMyApplication();
    final now = DateTime.now().toIso8601String();

    if (existing != null) {
      // Promote to Pending and stamp submitted_at
      await _db.from('applications').update({
        'status':       'Pending',
        'submitted_at': now,
        if (name.isNotEmpty)        'applicant_name': name,
        if (email.isNotEmpty)       'email':          email,
        if (nationality.isNotEmpty) 'nationality':    nationality,
      }).eq('id', existing['id'] as String);
      return existing['applicant_id'] as String? ?? '';
    }

    // No existing row — create a fresh application
    return submitApplication(
      applicantName: name,
      email:         email,
      type:          type,
      programme:     '',
      faculty:       '',
      nationality:   nationality,
    );
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

  /// Update the status (and optional notes) of an application,
  /// then send a notification to the applicant.
  static Future<void> updateApplicationStatus(
    String applicationId,
    String status, {
    String? notes,
  }) async {
    final update = <String, dynamic>{'status': status};
    if (notes != null) update['notes'] = notes;
    await _db.from('applications').update(update).eq('id', applicationId);

    // Notify the applicant
    try {
      final app = await _db
          .from('applications')
          .select('user_id, programme')
          .eq('id', applicationId)
          .maybeSingle();
      final recipientId = app?['user_id'] as String?;
      if (recipientId == null) return;

      final programme = app?['programme'] as String? ?? 'your programme';
      final String title;
      final String body;
      switch (status.toLowerCase()) {
        case 'approved':
          title = 'Application Approved!';
          body  = 'Congratulations! Your application for $programme has been approved. Check your dashboard for your offer letter.';
          break;
        case 'rejected':
          title = 'Application Decision';
          body  = 'Your application for $programme has been reviewed. Please contact the admissions office for further guidance.';
          break;
        default:
          title = 'Application Status Updated';
          body  = 'Your application status has been updated to: $status.';
      }
      await _db.from('notifications').insert({
        'recipient_id':   recipientId,
        'type':           'status_update',
        'title':          title,
        'body':           body,
        'metadata':       {'application_id': applicationId, 'status': status},
      });
    } catch (e) {
      debugPrint('updateApplicationStatus notify error (non-fatal): $e');
    }
  }

  /// Update the fee payment status of an application.
  static Future<void> updateApplicationFeePaid(
    String applicationId,
    bool paid,
  ) async {
    await _db.from('applications').update({
      'application_fee_paid': paid,
      'fee_paid_at': paid ? DateTime.now().toIso8601String() : null,
    }).eq('id', applicationId);
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

  /// Upload a document file to Supabase Storage, then save its record to the
  /// documents table.  Throws on any error so the caller can surface it.
  static Future<String?> uploadDocument({
    required String fileName,
    required String documentType,
    List<int>? fileBytes,
    String? applicationId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    String? storageUrl;

    // ── 1. Upload bytes to Supabase Storage (if provided) ──────────────────
    if (fileBytes != null && fileBytes.isNotEmpty) {
      try {
        final ext = fileName.contains('.')
            ? fileName.split('.').last.toLowerCase()
            : 'bin';
        final storagePath = 'documents/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        await _db.storage
            .from('applicant-documents')
            .uploadBinary(
              storagePath,
              Uint8List.fromList(fileBytes),
              fileOptions: FileOptions(
                contentType: _mimeForExt(ext),
                upsert: true,
              ),
            )
            .timeout(const Duration(seconds: 30));

        storageUrl = _db.storage
            .from('applicant-documents')
            .getPublicUrl(storagePath);
      } catch (e) {
        debugPrint('Storage upload error: $e');
        // Re-throw storage errors so the UI can show them
        rethrow;
      }
    }

    // ── 2. Save metadata row to documents table ────────────────────────────
    final app = applicationId != null ? {'id': applicationId} : await getMyApplication();

    final payload = <String, dynamic>{
      'user_id': uid,
      'file_name': fileName,
      'document_type': documentType,
      'verification_status': 'pending_review',
      'status': 'Pending',
      'uploaded_at': DateTime.now().toIso8601String(),
      if (storageUrl != null) 'file_url': storageUrl,
    };
    if (app != null) payload['application_id'] = app['id'];

    try {
      await _db.from('documents').insert(payload);
    } on PostgrestException catch (e) {
      if (_isMissingDocumentsTable(e)) {
        throw Exception(
          'Failed to save document metadata: database table public.documents is missing. '
          'Run migration supabase/migrations/20260404_fix_missing_documents_and_applicant_id.sql',
        );
      }
      rethrow;
    }
    return storageUrl;
  }

  static String _mimeForExt(String ext) {
    switch (ext) {
      case 'pdf':  return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      default:     return 'application/octet-stream';
    }
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
    try {
      await _db.rpc('admin_insert_programme', params: {
        'p_name': name,
        'p_faculty': faculty,
        'p_level': level,
        'p_duration_years': durationYears,
        'p_status': 'Active',
      });
    } catch (_) {
      // Backward compatibility if RPC is not yet deployed.
      await _db.from('programmes').insert({
        'name': name,
        'faculty': faculty,
        'level': level,
        'duration_years': durationYears,
        'status': 'Active',
      });
    }
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

  /// Real-time stream of current user's interviews.
  static Stream<List<Map<String, dynamic>>> streamMyInterviews() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _db
        .from('interviews')
        .stream(primaryKey: ['id'])
        .eq('applicant_id', uid)
        .order('scheduled_date', ascending: true);
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

  /// Real-time stream of admin notifications (recipient_role = 'admin').
  static Stream<List<Map<String, dynamic>>> streamAdminNotifications() {
    return _db
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_role', 'admin')
        .order('created_at', ascending: false);
  }

  /// Real-time stream of notifications for the current applicant user.
  static Stream<List<Map<String, dynamic>>> streamMyApplicantNotifications() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _db
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', uid)
        .order('created_at', ascending: false);
  }

  /// Mark every unread notification as read.
  static Future<void> markAllNotificationsRead() async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('is_read', false);
  }

  /// Mark all of the current user's notifications as read.
  static Future<void> markAllMyNotificationsRead() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', uid)
        .eq('is_read', false);
  }

  /// Mark all admin notifications as read.
  static Future<void> markAllAdminNotificationsRead() async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_role', 'admin')
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

  /// Insert a notification for a specific applicant user.
  static Future<void> insertNotificationForUser({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? metadata,
  }) async {
    await _db.from('notifications').insert({
      'recipient_id': recipientId,
      'recipient_role': 'applicant',
      'type': type,
      'title': title,
      'body': body,
      'metadata': metadata ?? {},
      'is_read': false,
    });
  }

  /// Insert a notification for the admin role (visible to all admins).
  static Future<void> insertAdminNotification({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? metadata,
  }) async {
    await _db.from('notifications').insert({
      'recipient_role': 'admin',
      'type': type,
      'title': title,
      'body': body,
      'metadata': metadata ?? {},
      'is_read': false,
    });
  }

  /// Fetch a single application row by its Supabase UUID.
  static Future<Map<String, dynamic>?> getApplicationById(String id) async {
    try {
      return await _db
          .from('applications')
          .select()
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      debugPrint('getApplicationById error: $e');
      return null;
    }
  }

  /// Update application status, add history, and send a notification to applicant.
  static Future<void> approveApplication({
    required String applicationId,
    required String applicantUserId,
    required String applicantName,
    required String programme,
    required String applicantType,
  }) async {
    await updateApplicationStatusWithHistory(applicationId, 'Approved',
        changedBy: currentUser?.email ?? 'Admin');
    try {
      await insertNotificationForUser(
        recipientId: applicantUserId,
        type: 'status_update',
        title: 'Application Approved 🎉',
        body: 'Congratulations! You have been enrolled at Africa University. '
            'Please check your offer letter.',
        metadata: {
          'application_id': applicationId,
          'programme': programme,
          'applicant_type': applicantType,
        },
      );
    } catch (e) {
      debugPrint('approveApplication notification error: $e');
    }
  }

  /// Update application status to denied and notify applicant with reason.
  static Future<void> denyApplication({
    required String applicationId,
    required String applicantUserId,
    required String reason,
    String? suggestedProgrammes,
  }) async {
    await updateApplicationStatusWithHistory(applicationId, 'Rejected',
        notes: reason, changedBy: currentUser?.email ?? 'Admin');
    try {
      final body = 'Your application has been reviewed. Unfortunately, it was '
          'not successful. Reason: $reason.'
          '${suggestedProgrammes != null && suggestedProgrammes.isNotEmpty ? ' Suggested programmes: $suggestedProgrammes.' : ''}';
      await insertNotificationForUser(
        recipientId: applicantUserId,
        type: 'status_update',
        title: 'Application Update',
        body: body,
        metadata: {
          'application_id': applicationId,
          'reason': reason,
          if (suggestedProgrammes != null) 'suggested_programmes': suggestedProgrammes,
        },
      );
    } catch (e) {
      debugPrint('denyApplication notification error: $e');
    }
  }

  /// Update application status to under_review and notify applicant.
  static Future<void> putApplicationUnderReview({
    required String applicationId,
    required String applicantUserId,
  }) async {
    await updateApplicationStatusWithHistory(applicationId, 'Under Review',
        changedBy: currentUser?.email ?? 'Admin');
    try {
      await insertNotificationForUser(
        recipientId: applicantUserId,
        type: 'status_update',
        title: 'Application Under Review',
        body: 'Your application is currently under review. You will be notified once a decision is made.',
        metadata: {'application_id': applicationId},
      );
    } catch (e) {
      debugPrint('putApplicationUnderReview notification error: $e');
    }
  }

  /// Insert notifications for all matching applicants (for announcements).
  static Future<void> broadcastAnnouncementToApplicants({
    required String title,
    required String body,
    String? audienceType, // null = all, 'local', 'international', 'postgraduate', etc.
    String? byStatus,    // null = all, 'Pending', 'Approved', etc.
  }) async {
    try {
      var query = _db.from('applications').select('user_id, type, status');
      if (audienceType != null) {
        query = query.ilike('type', '%$audienceType%');
      }
      if (byStatus != null) {
        query = query.eq('status', byStatus);
      }
      final rows = await query;
      final userIds = (rows as List)
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();
      for (final uid in userIds) {
        await _db.from('notifications').insert({
          'recipient_id': uid,
          'recipient_role': 'applicant',
          'type': 'announcement',
          'title': title,
          'body': body,
          'is_read': false,
        });
      }
    } catch (e) {
      debugPrint('broadcastAnnouncement error: $e');
    }
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
