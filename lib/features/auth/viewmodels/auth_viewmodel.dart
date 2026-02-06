import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

/// Authentication states
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// ViewModel for managing authentication state
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _savedEmail;
  bool _rememberMe = false;

  // Keys for SharedPreferences
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  // Getters
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get savedEmail => _savedEmail;
  bool get rememberMe => _rememberMe;
  bool get isLoading => _status == AuthStatus.loading;

  // Expose User and Session
  User? get currentUser => _authRepository.currentUser;
  Session? get currentSession => _authRepository.currentSession;

  /// Initialize - load saved preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (_rememberMe) {
        _savedEmail = prefs.getString(_savedEmailKey);
      }

      // Check current auth status on init
      if (_authRepository.currentUser != null) {
        _status = AuthStatus.authenticated;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AuthViewModel: Error loading preferences - $e');
    }
  }

  /// Toggle remember me
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    if (result.success) {
      _status = AuthStatus.authenticated;

      // Save preferences if remember me is checked
      await _savePreferences(email);

      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.error;
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Save email if remember me is checked
  Future<void> _savePreferences(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, _rememberMe);

      if (_rememberMe) {
        await prefs.setString(_savedEmailKey, email);
        _savedEmail = email;
      } else {
        await prefs.remove(_savedEmailKey);
        _savedEmail = null;
      }
    } catch (e) {
      debugPrint('AuthViewModel: Error saving preferences - $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _authRepository.signOut();

      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to sign out. Please try again.';
      notifyListeners();
      // Revert to authenticated if logout failed?
      // Usually strict logout handles this, but we'll show error.
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.sendPasswordResetEmail(email);

    _status = result.success ? AuthStatus.unauthenticated : AuthStatus.error;
    _errorMessage = result.errorMessage;
    notifyListeners();

    return result.success;
  }
}
