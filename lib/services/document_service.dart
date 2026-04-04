import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:au_connect/models/document.dart';
import 'package:au_connect/services/application_service.dart';
import 'package:au_connect/services/supabase_client_provider.dart';

class DocumentService {
  static final _client = SupabaseClientProvider.client;

  static Future<List<Document>> getDocuments(String applicationId) async {
    try {
      final res = await _client.from('documents').select().eq('application_id', applicationId).order('created_at', ascending: false);
      return (res as List).map((row) => Document.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('getDocuments error: $e');
      throw Exception('Failed to load documents: $e');
    }
  }

  static Future<List<Document>> getMyDocuments() async {
    final application = await ApplicationService.getMyApplication();
    if (application == null) return [];
    return getDocuments(application.id);
  }

  static Stream<List<Document>> streamMyDocuments() {
    final uid = SupabaseClientProvider.currentUserId;
    if (uid == null) return const Stream.empty();
    return _client
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('uploaded_at', ascending: false)
        .map((rows) => rows.map((row) => Document.fromJson(Map<String, dynamic>.from(row))).toList());
  }

  static Future<String?> uploadDocument({
    required String fileName,
    required String documentType,
    List<int>? fileBytes,
    String? applicationId,
  }) async {
    final uid = SupabaseClientProvider.currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    String? storageUrl;
    if (fileBytes != null && fileBytes.isNotEmpty) {
      try {
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'bin';
       final storagePath = 'documents/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

debugPrint('uid used in storagePath: $uid');
debugPrint('storagePath: $storagePath');

await _client.storage.from('applicant-documents').uploadBinary(
  storagePath,
  Uint8List.fromList(fileBytes),
  fileOptions: FileOptions(contentType: _mimeForExt(ext), upsert: true),
);
        storageUrl = _client.storage.from('applicant-documents').getPublicUrl(storagePath);
      } catch (e) {
        debugPrint('uploadDocument storage error: $e');
        throw Exception('Failed to upload document file: $e');
      }
    }

    try {
      final application = applicationId != null
          ? {'id': applicationId}
          : await ApplicationService.getMyApplication().then((value) => value == null ? null : {'id': value.id});

      final payload = <String, dynamic>{
        'user_id': uid,
        'file_name': fileName,
        'document_type': documentType,
        'verification_status': 'pending_review',
        'status': 'Pending',
        'uploaded_at': DateTime.now().toIso8601String(),
        if (storageUrl != null) 'file_url': storageUrl,
      };
      if (application != null) payload['application_id'] = application['id'];

      await _client.from('documents').insert(payload);
      return storageUrl;
    } on PostgrestException catch (e) {
      debugPrint('uploadDocument database error: $e');
      final msg = e.message.toLowerCase();
      if (e.code == 'PGRST205' && msg.contains('public.documents')) {
        throw Exception(
          'Failed to save document metadata: database table public.documents is missing. '
          'Run migration supabase/migrations/20260404_fix_missing_documents_and_applicant_id.sql',
        );
      }
      throw Exception('Failed to save document metadata: $e');
    } catch (e) {
      debugPrint('uploadDocument database error: $e');
      throw Exception('Failed to save document metadata: $e');
    }
  }

  static Future<void> setDocumentVerified(String docId, bool verified) async {
    try {
      await _client.from('documents').update({'verified': verified}).eq('id', docId);
    } catch (e) {
      debugPrint('setDocumentVerified error: $e');
      throw Exception('Failed to update document verification: $e');
    }
  }

  static Future<void> updateDocumentStatus(String docId, String status, {String? reviewedBy}) async {
    try {
      final payload = <String, dynamic>{'status': status};
      if (reviewedBy != null) payload['reviewed_by'] = reviewedBy;
      await _client.from('documents').update(payload).eq('id', docId);
    } catch (e) {
      debugPrint('updateDocumentStatus error: $e');
      throw Exception('Failed to update document status: $e');
    }
  }

  static Stream<List<Document>> streamAllDocuments() {
    return _client
        .from('documents')
        .stream(primaryKey: ['id'])
        .order('uploaded_at', ascending: false)
        .map((rows) => rows.map((row) => Document.fromJson(Map<String, dynamic>.from(row))).toList());
  }

  static String _mimeForExt(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
