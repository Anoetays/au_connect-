import 'package:flutter/foundation.dart';

import 'package:au_connect/models/application.dart';
import 'package:au_connect/models/document.dart';
import 'package:au_connect/models/profile.dart';
import 'package:au_connect/services/application_service.dart';
import 'package:au_connect/services/document_service.dart';
import 'package:au_connect/services/profile_service.dart';
import 'package:au_connect/services/supabase_client_provider.dart';

class AdminService {
  static final _client = SupabaseClientProvider.client;

  static Future<List<Profile>> getAllProfiles() => ProfileService.getAllProfiles();

  static Future<List<Application>> getAllApplications({String? status, String? type}) {
    return ApplicationService.getAllApplications(status: status, type: type);
  }

  static Stream<List<Application>> streamAllApplications() => ApplicationService.streamAllApplications();

  static Future<List<Document>> getAllDocuments() async {
    try {
      final res = await _client.from('documents').select().order('uploaded_at', ascending: false);
      return (res as List).map((row) => Document.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('getAllDocuments error: $e');
      throw Exception('Failed to load documents: $e');
    }
  }

  static Stream<List<Document>> streamAllDocuments() => DocumentService.streamAllDocuments();

  static Stream<List<Map<String, dynamic>>> streamStaff() {
    return _client.from('staff').stream(primaryKey: ['id']).order('name', ascending: true);
  }

  static Future<void> inviteStaff({
    required String name,
    required String email,
    required String role,
    String? department,
  }) async {
    try {
      await _client.from('staff').insert({
        'name': name,
        'email': email,
        'role': role,
        'status': 'Pending',
        if (department != null) 'department': department,
      });
    } catch (e) {
      debugPrint('inviteStaff error: $e');
      throw Exception('Failed to invite staff: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> streamInterviews() {
    return _client.from('interviews').stream(primaryKey: ['id']).order('scheduled_date', ascending: true);
  }

  static Future<void> updateInterviewStatus(String interviewId, String status) async {
    try {
      await _client.from('interviews').update({'status': status}).eq('id', interviewId);
    } catch (e) {
      debugPrint('updateInterviewStatus error: $e');
      throw Exception('Failed to update interview status: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAnnouncements(String role) async {
    try {
      final res = await _client.from('announcements').select().or('target_role.eq.$role,target_role.eq.all').order('created_at', ascending: false).limit(10);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getAnnouncements error: $e');
      throw Exception('Failed to load announcements: $e');
    }
  }

  static Future<void> createAnnouncement({
    required String title,
    required String body,
    required String targetRole,
  }) async {
    try {
      final uid = SupabaseClientProvider.currentUserId;
      if (uid == null) throw Exception('Not authenticated');
      await _client.from('announcements').insert({
        'title': title,
        'body': body,
        'target_role': targetRole,
        'created_by': uid,
      });
    } catch (e) {
      debugPrint('createAnnouncement error: $e');
      throw Exception('Failed to create announcement: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getProgrammeRequirements(String programmeName) async {
    try {
      final res = await _client.from('programme_requirements').select().eq('programme_name', programmeName);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getProgrammeRequirements error: $e');
      throw Exception('Failed to load programme requirements: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getProgrammesByFaculty(String faculty) async {
    try {
      final res = await _client.from('programmes').select().eq('faculty', faculty).eq('status', 'Active');
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('getProgrammesByFaculty error: $e');
      throw Exception('Failed to load programmes: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> streamProgrammes() {
    return _client.from('programmes').stream(primaryKey: ['id']).order('name', ascending: true);
  }

  static Future<void> insertProgramme({
    required String name,
    required String faculty,
    required String level,
    required int durationYears,
  }) async {
    try {
      await _client.rpc('admin_insert_programme', params: {
        'p_name': name,
        'p_faculty': faculty,
        'p_level': level,
        'p_duration_years': durationYears,
        'p_status': 'Active',
      });
    } catch (_) {
      try {
        // Backward compatibility if RPC is not yet deployed.
        await _client.from('programmes').insert({
          'name': name,
          'faculty': faculty,
          'level': level,
          'duration_years': durationYears,
          'status': 'Active',
        });
      } catch (e) {
        debugPrint('insertProgramme error: $e');
        throw Exception('Failed to add programme: $e');
      }
    }
  }

  static Future<void> updateProgramme(
    String id, {
    required String name,
    required String faculty,
    required String level,
    required int durationYears,
  }) async {
    try {
      await _client.from('programmes').update({
        'name': name,
        'faculty': faculty,
        'level': level,
        'duration_years': durationYears,
      }).eq('id', id);
    } catch (e) {
      debugPrint('updateProgramme error: $e');
      throw Exception('Failed to update programme: $e');
    }
  }

  static Future<void> deleteProgramme(String id) async {
    try {
      await _client.from('programmes').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteProgramme error: $e');
      throw Exception('Failed to delete programme: $e');
    }
  }
}
