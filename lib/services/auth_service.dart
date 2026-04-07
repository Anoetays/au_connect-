import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream to listen to auth state changes
  Stream<AuthState> get user => _supabase.auth.onAuthStateChange;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;
  
  // Check if user email is verified
  bool get isEmailVerified => _supabase.auth.currentUser?.emailConfirmedAt != null;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('Sign-in error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during sign-in: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password, {String? fullName}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? '',
        },
      );
      
      // Trigger will auto-create profile, but we can also do it manually if needed
      if (response.user != null) {
        try {
          await _createUserProfile(response.user!.id, email, fullName);
        } catch (profileError) {
          debugPrint('Warning: Could not create profile: $profileError');
          // Don't rethrow - profile will be created by trigger
        }
      }
      
      return response;
    } on AuthException catch (e) {
      debugPrint('Sign-up error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during sign-up: $e');
      rethrow;
    }
  }

  /// Create user profile in profiles table
  Future<void> _createUserProfile(String userId, String email, String? fullName) async {
    try {
      await _supabase.from('profiles').upsert({
        'user_id': userId,
        'email': email,
        'full_name': fullName ?? '',
        'role': 'applicant',
      });
    } catch (e) {
      debugPrint('Error creating profile: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'none';
      debugPrint('Signing out user ID: $userId');
      _supabase.removeAllChannels();
      await _supabase.auth.signOut();
      debugPrint('Signed out user ID: $userId');
    } catch (e) {
      debugPrint('Sign-out error: $e');
      rethrow;
    }
  }

  /// Get user role from profiles table
  Future<String?> getUserRole() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }
}
