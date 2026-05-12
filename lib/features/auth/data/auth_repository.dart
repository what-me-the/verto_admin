import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// Result class for auth operations
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  AuthResult({required this.success, this.errorMessage, this.user});

  factory AuthResult.success(User user) =>
      AuthResult(success: true, user: user);

  factory AuthResult.failure(String message) =>
      AuthResult(success: false, errorMessage: message);
}

/// Repository for authentication operations
class AuthRepository {
  final SupabaseService _supabaseService;

  AuthRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Sign in with email and password
  /// Validates admin role after successful auth
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthRepository: Attempting sign in for $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure('Sign in failed. Please try again.');
      }

      // Verify admin role
      final isAdmin = await _verifyAdminRole(response.user!.id);
      if (!isAdmin) {
        // Sign out non-admin user
        await _client.auth.signOut();
        return AuthResult.failure(
          'Access denied. This portal is for administrators only.',
        );
      }

      debugPrint('AuthRepository: Sign in successful for admin user');
      return AuthResult.success(response.user!);
    } on AuthException catch (e) {
      debugPrint('AuthRepository: AuthException - ${e.message}');
      debugPrint('AuthRepository: StatusCode - ${e.statusCode}');
      // TEMPORARY: Return raw message for debugging
      return AuthResult.failure('Debug Error: ${e.message}');
    } catch (e) {
      debugPrint('AuthRepository: Unknown error - $e');
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Verify if user has admin role
  Future<bool> _verifyAdminRole(String userId) async {
    try {
      final response = await _client
          .from('admin_users')
          .select('id, is_active')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('AuthRepository: Error verifying admin role - $e');
      return false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      debugPrint('AuthRepository: User signed out');
    } catch (e) {
      debugPrint('AuthRepository: Error signing out - $e');
      rethrow; // Rethrow to let ViewModel handle UI feedback
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return AuthResult(success: true, errorMessage: null);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure(
        'Failed to send reset email. Please try again.',
      );
    }
  }

  /// Map Supabase auth errors to user-friendly messages
  String _mapAuthError(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid login credentials') ||
        lowerMessage.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (lowerMessage.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }

    if (lowerMessage.contains('too many requests')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }

    if (lowerMessage.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }

    return message;
  }
}
