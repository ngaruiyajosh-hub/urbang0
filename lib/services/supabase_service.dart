import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service for Supabase client initialization and management
class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;

  /// Initialize Supabase with environment variables
  static Future<void> initialize() async {
    if (_client != null) return;

    String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      final assetConfig = await _loadEnvFromAsset();
      supabaseUrl = assetConfig['SUPABASE_URL'] ?? supabaseUrl;
      supabaseAnonKey =
          assetConfig['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
    }

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint('Supabase credentials not configured');
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = Supabase.instance.client;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;

  static Future<Map<String, String>> _loadEnvFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString('env.json');
      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return data.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      debugPrint('Failed to load env.json: $e');
      return <String, String>{};
    }
  }
}
