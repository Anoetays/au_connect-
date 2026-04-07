import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:au_connect/models/application.dart';
import 'package:au_connect/models/document.dart';
import 'package:au_connect/models/profile.dart';
import 'package:au_connect/services/application_service.dart';
import 'package:au_connect/services/document_service.dart';
import 'package:au_connect/services/profile_service.dart';
import 'package:au_connect/services/supabase_client_provider.dart';

const String _backendUrl = 'http://localhost:3000/api';

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

  // ─────────────────────────────────────────────────────────────
  // NEW ADVANCED ADMIN FEATURES (from backend API)
  // ─────────────────────────────────────────────────────────────

  /// Get admin dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/admin/dashboard'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      throw Exception('Failed to fetch dashboard stats');
    } catch (e) {
      debugPrint('getDashboardStats error: $e');
      throw Exception('Dashboard stats error: $e');
    }
  }

  /// Get all applications with filtering
  static Future<Map<String, dynamic>> getApplicationsFiltered({
    int offset = 0,
    int limit = 20,
    String? status,
    String? programme,
  }) async {
    try {
      String query = '$_backendUrl/admin/applications?offset=$offset&limit=$limit';
      if (status != null) query += '&status=$status';
      if (programme != null) query += '&programme=$programme';

      final response = await http.get(Uri.parse(query));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch applications');
    } catch (e) {
      debugPrint('getApplicationsFiltered error: $e');
      throw Exception('Get applications error: $e');
    }
  }

  /// Get detailed application with documents
  static Future<Map<String, dynamic>> getApplicationDetail(int appId) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/admin/applications/$appId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      throw Exception('Failed to fetch application detail');
    } catch (e) {
      debugPrint('getApplicationDetail error: $e');
      throw Exception('Get application detail error: $e');
    }
  }

  /// Review/update application status
  static Future<Map<String, dynamic>> reviewApplication({
    required int appId,
    required String status,
    String? reviewNotes,
    String? reviewedBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/admin/applications/$appId/review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'reviewNotes': reviewNotes,
          'reviewedBy': reviewedBy ?? 'admin',
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      throw Exception('Failed to review application');
    } catch (e) {
      debugPrint('reviewApplication error: $e');
      throw Exception('Review application error: $e');
    }
  }

  /// Verify document status
  static Future<Map<String, dynamic>> verifyDocument({
    required String docId,
    required String status,
    String? verificationNotes,
    String? verifiedBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/admin/documents/$docId/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'verificationNotes': verificationNotes,
          'verifiedBy': verifiedBy ?? 'admin',
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      throw Exception('Failed to verify document');
    } catch (e) {
      debugPrint('verifyDocument error: $e');
      throw Exception('Verify document error: $e');
    }
  }

  /// Send bulk notifications
  static Future<Map<String, dynamic>> sendBulkNotifications({
    required String recipientRole,
    required String type,
    required String title,
    String? body,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/admin/notifications/bulk'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipient_role': recipientRole,
          'type': type,
          'title': title,
          'body': body,
          'filters': filters,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to send notifications');
    } catch (e) {
      debugPrint('sendBulkNotifications error: $e');
      throw Exception('Send bulk notifications error: $e');
    }
  }

  /// Export applications report
  static Future<String> exportReport({
    required String format, // 'json' or 'csv'
    String? status,
    String? programme,
  }) async {
    try {
      String query = '$_backendUrl/admin/reports/export?format=$format';
      if (status != null) query += '&status=$status';
      if (programme != null) query += '&programme=$programme';

      final response = await http.get(Uri.parse(query));
      if (response.statusCode == 200) {
        return response.body;
      }
      throw Exception('Failed to export report');
    } catch (e) {
      debugPrint('exportReport error: $e');
      throw Exception('Export report error: $e');
    }
  }
}
