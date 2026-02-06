import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Access the initialized Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Simple helper to get the current user session
  static Session? get session => client.auth.currentSession;

  /// Get current user
  static User? get user => client.auth.currentUser;

  /// Sign out helper
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
