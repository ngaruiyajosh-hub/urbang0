import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Authentication service for user management
class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  /// Get current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Sign in successful: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      debugPrint('❌ Sign in failed: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }

  /// Sign up with email, password, and user metadata
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role, 'phone_number': phoneNumber},
      );
      debugPrint('✅ Sign up successful: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      debugPrint('❌ Sign up failed: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      debugPrint('✅ Sign out successful');
    } on AuthException catch (e) {
      debugPrint('❌ Sign out failed: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  /// Get user profile from User table
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('User')
          .select()
          .eq('auth_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('❌ Get user profile error: $e');
      return null;
    }
  }

  /// Update user profile in User table
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? role,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phone number'] = phoneNumber;
      if (role != null) updates['role'] = role;

      await _client.from('User').update(updates).eq('auth_id', userId);
      debugPrint('✅ User profile updated');
    } catch (e) {
      debugPrint('❌ Update user profile error: $e');
      rethrow;
    }
  }
}
