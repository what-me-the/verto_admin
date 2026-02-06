import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service for Supabase client management
class SupabaseService {
  SupabaseService._();
  static final SupabaseService _instance = SupabaseService._();
  static SupabaseService get instance => _instance;

  static const String _supabaseUrl = 'https://lmcprhecgakxahccqntf.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxtY3ByaGVjZ2FreGFoY2NxbnRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwMDczMTIsImV4cCI6MjA4NTU4MzMxMn0.uq1iVeWE-7narVDiBu5TGT0LnR3klIHKMwc9g8X2bVA';

  bool _isInitialized = false;

  /// Initialize Supabase client
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      debug: kDebugMode,
    );

    _isInitialized = true;
    debugPrint('SupabaseService: Initialized successfully');
    debugPrint('SupabaseService: URL: $_supabaseUrl');
    debugPrint(
      'SupabaseService: Key (masked): ${_supabaseAnonKey.substring(0, 5)}...${_supabaseAnonKey.substring(_supabaseAnonKey.length - 5)}',
    );
  }

  /// Get Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Get current session
  Session? get currentSession => client.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
