import 'package:email_auth/email_auth.dart';
import 'package:flutter/foundation.dart';
import '../appwrite/appwrite_config.dart';

/// Wrapper around `email_auth` package for OTP send / verify.
///
/// Primary OTP provider for password-reset. Falls back to custom OTP
/// (MailApi/Gmail) when remote server is not configured or fails.
///
/// Config via --dart-define:
///   --dart-define=EMAIL_AUTH_SERVER=https://your-email-auth-node.com
///   --dart-define=EMAIL_AUTH_SERVER_KEY=yourServerKey
///
/// If both are empty, the package uses its default test server (limited 30 mails,
/// obsolete — see https://github.com/saran-surya/email_auth/discussions/74).
/// For production, deploy https://github.com/saran-surya/email_auth_node
/// and set the two defines above.
///
/// Session name is fixed to "Hari Om Traders" for OTP email branding.
class EmailAuthService {
  EmailAuthService._();
  static final EmailAuthService instance = EmailAuthService._();

  EmailAuth? _emailAuth;
  bool _remoteConfigured = false;

  EmailAuth get _auth {
    if (_emailAuth != null) return _emailAuth!;
    _emailAuth = EmailAuth(sessionName: 'Hari Om Traders');
    final server = AppwriteConfig.emailAuthServer.trim();
    final key = AppwriteConfig.emailAuthServerKey.trim();
    if (server.isNotEmpty) {
      try {
        // config() returns Future<bool> in 2.0.0 — fire-and-forget, update flag when complete
        _emailAuth!.config({'server': server, 'serverKey': key}).then((ok) {
          _remoteConfigured = ok;
          debugPrint('[EmailAuthService] remote server configured: $ok → $server');
        }).catchError((e) {
          debugPrint('[EmailAuthService] config failed: $e');
        });
      } catch (e) {
        debugPrint('[EmailAuthService] config sync failed: $e');
      }
    } else {
      debugPrint('[EmailAuthService] using default server — set EMAIL_AUTH_SERVER for production');
    }
    return _emailAuth!;
  }

  bool get isRemoteConfigured => _remoteConfigured;
  bool get isAvailable => true; // package always available; server may be default

  /// Send OTP to [email]. Returns true on success.
  Future<bool> sendOtp({required String email, int otpLength = 6}) async {
    final normalized = email.trim().toLowerCase();
    try {
      final ok = await _auth.sendOtp(recipientMail: normalized, otpLength: otpLength)
          .timeout(const Duration(seconds: 10));
      debugPrint('[EmailAuthService] sendOtp $normalized → $ok (remoteConfigured=$_remoteConfigured)');
      return ok;
    } catch (e) {
      debugPrint('[EmailAuthService] sendOtp exception: $e');
      return false;
    }
  }

  /// Validate [otp] for [email]. Synchronous per package API.
  bool verifyOtp({required String email, required String otp}) {
    final normalized = email.trim().toLowerCase();
    final code = otp.trim();
    try {
      final ok = _auth.validateOtp(recipientMail: normalized, userOtp: code);
      debugPrint('[EmailAuthService] validateOtp $normalized → $ok');
      return ok;
    } catch (e) {
      debugPrint('[EmailAuthService] validateOtp exception: $e');
      return false;
    }
  }
}
