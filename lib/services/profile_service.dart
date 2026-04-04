import 'package:flutter/foundation.dart';

import 'package:au_connect/models/profile.dart';
import 'package:au_connect/services/supabase_client_provider.dart';

class ProfileService {
  static final _client = SupabaseClientProvider.client;

  static Future<Profile?> getMyProfile() async {
    final uid = SupabaseClientProvider.currentUserId;
    if (uid == null) return null;

    try {
      final row = await _client.from('profiles').select().eq('user_id', uid).maybeSingle();
      if (row == null) return null;
      return Profile.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      debugPrint('getMyProfile error: $e');
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('42501') || errorText.contains('permission denied for table profiles')) {
        // Allow sign-in to continue even if profile grants are temporarily misconfigured.
        return null;
      }
      throw Exception('Failed to load profile: $e');
    }
  }

  static Future<Profile> upsertProfile(Profile profile) async {
    final uid = SupabaseClientProvider.currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    try {
      final payload = profile.toJson();
      payload['user_id'] = uid;

      await _client.from('profiles').upsert(
        payload,
        onConflict: 'user_id',
      );

      return profile.copyWith(userId: uid);
    } catch (e) {
      debugPrint('upsertProfile error: $e');
      throw Exception('Failed to save profile: $e');
    }
  }

  static Future<List<Profile>> getAllProfiles() async {
    try {
      final res = await _client.from('profiles').select().order('created_at', ascending: false);
      return (res as List).map((row) => Profile.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      debugPrint('getAllProfiles error: $e');
      throw Exception('Failed to load profiles: $e');
    }
  }

  static Future<bool> isProfileComplete() async {
    final profile = await getMyProfile();
    return profile?.isComplete ?? false;
  }
}
