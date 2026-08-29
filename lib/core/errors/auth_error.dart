import 'package:appwrite/appwrite.dart';

/// Maps raw [AppwriteException] / network errors to user-friendly messages.
/// Never exposes internal secrets, OTPs, or stack traces.
class AuthError {
  static String friendly(Object e) {
    if (e is AppwriteException) {
      final code = e.code ?? 0;
      final msg = (e.message ?? '').toLowerCase();
      // 409 — duplicate
      if (code == 409 || msg.contains('already exists') || msg.contains('user already exists')) {
        return 'An account with this email already exists.';
      }
      // 401 — invalid credentials
      if (code == 401 || msg.contains('invalid credentials') || msg.contains('invalid email or password')) {
        return 'Incorrect email or password.';
      }
      // 404 — not found
      if (code == 404 || msg.contains('not found')) {
        // Distinguish user-not-found during recovery vs generic
        if (msg.contains('user')) return 'No account found with this email.';
        return 'Account not found. Please check your email.';
      }
      // 429 — rate limit
      if (code == 429 || msg.contains('rate limit') || msg.contains('too many')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      // Password / validation
      if (msg.contains('password')) {
        if (msg.contains('at least') || msg.contains('short')) return 'Password does not meet requirements.';
        return 'Invalid password. Please try again.';
      }
      if (msg.contains('invalid email')) return 'Please enter a valid email address.';
      if (msg.contains('email already')) return 'An account with this email already exists.';
      if (code == 400) return e.message ?? 'Invalid request. Please check your input.';
      if (e.message != null && e.message!.trim().isNotEmpty) {
        // Cap length, sanitize — never leak secrets
        final m = e.message!.trim();
        if (m.length > 180) return '${m.substring(0, 180)}…';
        return m;
      }
      return 'Something went wrong. Please try again.';
    }
    final s = e.toString().toLowerCase();
    if (s.contains('network') || s.contains('socket') || s.contains('failed host') || s.contains('connection')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    if (s.contains('timeout')) return 'Request timed out. Please check your internet connection.';
    if (s.contains('appwrite not configured') || s.contains('not initialized')) {
      return 'Service not configured. Please contact support.';
    }
    // Fallback — generic, safe
    return 'Something went wrong. Please try again.';
  }

  static bool isNetwork(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('network') || s.contains('socket') || s.contains('timeout') || s.contains('failed host') || s.contains('connection');
  }

  static bool isNotFound(Object e) {
    if (e is AppwriteException) return e.code == 404;
    return e.toString().toLowerCase().contains('not found');
  }

  static bool isDuplicate(Object e) {
    if (e is AppwriteException) return e.code == 409;
    return e.toString().toLowerCase().contains('already exists');
  }
}
