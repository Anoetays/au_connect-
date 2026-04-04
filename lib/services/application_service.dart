import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:au_connect/models/application.dart';
import 'package:au_connect/models/profile.dart';
import 'package:au_connect/services/profile_service.dart';
import 'package:au_connect/services/supabase_client_provider.dart';

class ApplicationService {
  static final _client = SupabaseClientProvider.client;
  static final _random = Random.secure();

  static String _randomToken(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  static String generateApplicantId() {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    return 'AU-$timestamp-${_randomToken(6)}';
  }

  static Future<Application?> getMyApplication() async {
    final uid = SupabaseClientProvider.currentUserId;
    if (uid == null) return null;

    try {
      final row = await _client
          .from('applications')
          .select()
          .eq('user_id', uid)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return Application.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      debugPrint('getMyApplication error: $e');
      throw Exception('Failed to load application: $e');
    }
  }

  static Future<Application> submitApplication({
    required Profile profile,
    required String type,
    required String programme,
    required String faculty,
    required String nationality,
    String? phone,
    String? source,
  }) async {
    final uid = SupabaseClientProvider.currentUserId;
    if (uid == null) throw Exception('Not authenticated');
    if (!profile.isComplete) {
      throw Exception('Profile is incomplete. Please complete all required fields first.');
    }

    final applicationCode = generateApplicantId();
    final now = DateTime.now().toIso8601String();
    final fallbackEmail = SupabaseClientProvider.currentUser?.email ?? '';
    final applicantName = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()
        : (fallbackEmail.isNotEmpty ? fallbackEmail.split('@').first : 'Applicant');
    final email = profile.email.trim().isNotEmpty ? profile.email.trim() : fallbackEmail;

    final payload = {
      'application_code': applicationCode,
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

    try {
      final row = await _client.from('applications').insert(payload).select().single();
      return Application.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      debugPrint('submitApplication error: $e');
      throw Exception('Failed to submit application: $e');
    }
  }

  static Future<Application> finalizeSubmission() async {
    final profile = await ProfileService.getMyProfile();
    if (profile == null) throw Exception('Profile not found');
    if (!profile.isComplete) {
      throw Exception('Profile is incomplete. Please complete your profile before submitting.');
    }

    final existing = await getMyApplication();
    if (existing != null) {
      try {
        final row = await _client.from('applications').update({
          'status': 'Pending',
          'submitted_at': DateTime.now().toIso8601String(),
          if (profile.fullName.isNotEmpty) 'applicant_name': profile.fullName,
          if (profile.email.isNotEmpty) 'email': profile.email,
          if (profile.countryOfOrigin.isNotEmpty) 'nationality': profile.countryOfOrigin,
        }).eq('id', existing.id).select().single();
        return Application.fromJson(Map<String, dynamic>.from(row));
      } catch (e) {
        debugPrint('finalizeSubmission update error: $e');
        throw Exception('Failed to finalize submission: $e');
      }
    }

    return submitApplication(
      profile: profile,
      type: profile.applicantType,
      programme: '',
      faculty: '',
      nationality: profile.countryOfOrigin,
      phone: profile.phone,
    );
  }

  static Future<void> updateApplicationProgramme(
    String applicationId, {
    required String programme,
    required String faculty,
  }) async {
    try {
      await _client.from('applications').update({
        'programme': programme,
        'faculty': faculty,
      }).eq('id', applicationId);
    } catch (e) {
      debugPrint('updateApplicationProgramme error: $e');
      throw Exception('Failed to update programme: $e');
    }
  }

  static Future<void> updateApplicationFeePaid(String applicationId, bool paid) async {
    try {
      await _client.from('applications').update({
        'application_fee_paid': paid,
        'fee_paid_at': paid ? DateTime.now().toIso8601String() : null,
      }).eq('id', applicationId);
    } catch (e) {
      debugPrint('updateApplicationFeePaid error: $e');
      throw Exception('Failed to update payment status: $e');
    }
  }

  static Future<void> updateApplicationStatus(
    String applicationId,
    String status, {
    String? notes,
  }) async {
    try {
      final update = <String, dynamic>{'status': status};
      if (notes != null) update['notes'] = notes;
      await _client.from('applications').update(update).eq('id', applicationId);
    } catch (e) {
      debugPrint('updateApplicationStatus error: $e');
      throw Exception('Failed to update application status: $e');
    }
  }

  static Future<List<Application>> getAllApplications({String? status, String? type}) async {
    try {
      var query = _client.from('applications').select();
      if (status != null) query = query.eq('status', status);
      if (type != null) query = query.eq('type', type);
      final res = await query.order('submitted_at', ascending: false);
      return (res as List).map((row) => Application.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('getAllApplications error: $e');
      throw Exception('Failed to load applications: $e');
    }
  }

  static Stream<List<Application>> streamMyApplications() {
    final uid = SupabaseClientProvider.currentUserId;
    if (uid == null) return const Stream.empty();
    return _client
        .from('applications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('submitted_at', ascending: false)
        .map((rows) => rows.map((row) => Application.fromJson(Map<String, dynamic>.from(row))).toList());
  }

  static Stream<List<Application>> streamAllApplications() {
    return _client
        .from('applications')
        .stream(primaryKey: ['id'])
        .order('submitted_at', ascending: false)
        .map((rows) => rows.map((row) => Application.fromJson(Map<String, dynamic>.from(row))).toList());
  }
}
