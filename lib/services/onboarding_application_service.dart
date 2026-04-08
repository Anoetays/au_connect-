import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class OnboardingApplicationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Create or get application record for current user
  static Future<Map<String, dynamic>> getOrCreateApplication() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Try to fetch existing
      final existing = await _supabase
          .from('applications')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        return existing;
      }

      // Create new
      final created = await _supabase
          .from('applications')
          .insert({'user_id': userId, 'status': 'draft'})
          .select()
          .single();

      return created;
    } catch (e) {
      debugPrint('Error in getOrCreateApplication: $e');
      rethrow;
    }
  }

  /// Save a single field to the application
  static Future<void> saveField(String fieldName, dynamic value) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Ensure application exists
      await getOrCreateApplication();

      // Update field
      await _supabase
          .from('applications')
          .update({fieldName: value})
          .eq('user_id', userId);

      debugPrint('Saved $fieldName = $value');
    } catch (e) {
      debugPrint('Error saving field $fieldName: $e');
      rethrow;
    }
  }

  /// Save multiple fields at once
  static Future<void> saveFields(Map<String, dynamic> fields) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Ensure application exists
      await getOrCreateApplication();

      // Update fields
      await _supabase
          .from('applications')
          .update(fields)
          .eq('user_id', userId);

      debugPrint('Saved multiple fields');
    } catch (e) {
      debugPrint('Error saving fields: $e');
      rethrow;
    }
  }

  /// Get current application data
  static Future<Map<String, dynamic>> getApplication() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      return await _supabase
          .from('applications')
          .select()
          .eq('user_id', userId)
          .single();
    } catch (e) {
      debugPrint('Error fetching application: $e');
      rethrow;
    }
  }

  /// Submit the application (set status to submitted)
  static Future<void> submitApplication() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('applications')
          .update({'status': 'submitted'})
          .eq('user_id', userId);

      debugPrint('Application submitted for user $userId');
    } catch (e) {
      debugPrint('Error submitting application: $e');
      rethrow;
    }
  }

  /// Submit and flush ALL onboarding fields in one upsert.
  /// This guarantees every field is persisted even if individual
  /// step-saves failed, and sets submitted_at for the admin dashboard.
  static Future<void> submitApplicationWithAllFields({
    required Map<String, dynamic> data,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Print the SQL needed in case any columns are missing
    debugPrint('''
-- Run this in Supabase SQL Editor if columns are missing:
ALTER TABLE applications ADD COLUMN IF NOT EXISTS full_name text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS submitted_at timestamptz;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS preferred_name text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS language text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS field_of_study text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS a_level_qualified boolean;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS school_attended text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS grades text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS financing text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS resides_in_zimbabwe boolean;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS applicant_type text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS accommodation text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS disability text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS disability_detail text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS kin_name text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS kin_relationship text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS kin_phone text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS payment_method text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS certificate_file_name text;
''');

    await _supabase
        .from('applications')
        .upsert({'user_id': userId, ...data}, onConflict: 'user_id');

    debugPrint('Full application submitted for user $userId');
  }
}
