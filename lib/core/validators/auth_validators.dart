/// Centralized validators — single source of truth for UI + service.
/// Messages are user-facing and locale-ready.
class AuthValidators {
  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateName(String? v) {
    if (v == null || v.trim().length < 2) return 'Enter your full name';
    if (v.trim().length > 128) return 'Name is too long';
    return null;
  }

  static String? validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter your email';
    if (!_emailRe.hasMatch(s)) return 'Please enter a valid email address.';
    if (s.length > 255) return 'Email is too long';
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Enter your password';
    if (v.length < 8) return 'Password must be at least 8 characters';
    // Optional strength hint — not blocking, but Appwrite enforces min 8
    return null;
  }

  static String? validatePasswordStrong(String? v) {
    final base = validatePassword(v);
    if (base != null) return base;
    // Encourage but don't block: if missing complexity, still allow
    return null;
  }

  static String? validateConfirm(String? confirm, String original) {
    if (confirm == null || confirm.isEmpty) return 'Confirm your password';
    if (confirm != original) return 'Passwords do not match';
    return null;
  }

  static String? validateOtp(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter the 6-digit OTP';
    if (!RegExp(r'^\d{6}$').hasMatch(s)) return 'OTP must be 6 digits';
    return null;
  }

  static bool isValidEmail(String e) => _emailRe.hasMatch(e.trim());
}
