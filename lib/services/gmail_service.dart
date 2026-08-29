import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../appwrite/appwrite_config.dart';

/// Service for sending emails via Gmail API using OAuth authentication.
///
/// Requires Google Cloud Console setup:
/// 1. Enable Gmail API
/// 2. Create OAuth 2.0 Client ID (Web application)
/// 3. Add authorized JavaScript origins and redirect URIs
///
/// Build command:
/// ```bash
/// flutter run \
///   --dart-define=GMAIL_CLIENT_ID=your-client-id.apps.googleusercontent.com \
///   --dart-define=GMAIL_SENDER_EMAIL=your@gmail.com
/// ```
class GmailService {
  GmailService._();
  static final GmailService instance = GmailService._();

  static const String _senderEmailKey = 'gmail_sender_email';
  static const String _isAuthenticatedKey = 'gmail_is_authenticated';

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb && AppwriteConfig.gmailClientId.isNotEmpty ? AppwriteConfig.gmailClientId : null,
    scopes: const [
      'https://www.googleapis.com/auth/gmail.send',
      'https://www.googleapis.com/auth/userinfo.email',
    ],
  );

  GoogleSignInAccount? _currentUser;
  AuthClient? _authClient;
  bool _isInitialized = false;

  /// Whether the user is currently signed in to Gmail.
  bool get isSignedIn => _currentUser != null && _authClient != null;

  /// The signed-in Gmail address.
  String? get senderEmail => _currentUser?.email;

  /// Initialize the service and restore previous session if available.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // Try to restore previous sign-in
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        _authClient = await _googleSignIn.authenticatedClient();
        debugPrint('[GmailService] Session restored for ${_currentUser?.email}');
      }
    } catch (e) {
      debugPrint('[GmailService] Failed to restore session: $e');
      _currentUser = null;
      _authClient = null;
    }
  }

  /// Sign in with Google and authorize Gmail access.
  /// Returns true if sign-in was successful.
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        debugPrint('[GmailService] Sign-in cancelled by user');
        return false;
      }

      _authClient = await _googleSignIn.authenticatedClient();
      if (_authClient == null) {
        debugPrint('[GmailService] Failed to get authenticated client');
        return false;
      }

      // Store authentication state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_senderEmailKey, _currentUser!.email);
      await prefs.setBool(_isAuthenticatedKey, true);

      debugPrint('[GmailService] Signed in as ${_currentUser?.email}');
      return true;
    } catch (e) {
      debugPrint('[GmailService] Sign-in failed: $e');
      return false;
    }
  }

  /// Sign out from Google.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _authClient = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_senderEmailKey);
      await prefs.remove(_isAuthenticatedKey);

      debugPrint('[GmailService] Signed out');
    } catch (e) {
      debugPrint('[GmailService] Sign-out failed: $e');
    }
  }

  /// Send an email via Gmail API.
  ///
  /// [to] - Recipient email address
  /// [subject] - Email subject
  /// [htmlBody] - HTML body content
  /// [from] - Sender email (optional, defaults to signed-in account)
  ///
  /// Returns true if email was sent successfully.
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String? from,
  }) async {
    if (!isSignedIn) {
      debugPrint('[GmailService] Not signed in. Call signIn() first.');
      return false;
    }

    try {
      final senderAddress = from ?? senderEmail;
      if (senderAddress == null || senderAddress.isEmpty) {
        debugPrint('[GmailService] No sender email available');
        return false;
      }

      // Build MIME message
      final mimeMessage = _buildMimeMessage(
        from: senderAddress,
        to: to,
        subject: subject,
        htmlBody: htmlBody,
      );

      // Encode to base64url for Gmail API
      final rawMessage = base64Url.encode(utf8.encode(mimeMessage));

      // Send via Gmail API
      final gmailApi = gmail.GmailApi(_authClient!);
      final message = gmail.Message()..raw = rawMessage;

      await gmailApi.users.messages.send(message, 'me');

      debugPrint('[GmailService] Email sent to $to');
      return true;
    } catch (e) {
      debugPrint('[GmailService] Failed to send email: $e');
      return false;
    }
  }

  /// Build a MIME message for HTML email.
  String _buildMimeMessage({
    required String from,
    required String to,
    required String subject,
    required String htmlBody,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('From: $from');
    buffer.writeln('To: $to');
    buffer.writeln('Subject: $subject');
    buffer.writeln('MIME-Version: 1.0');
    buffer.writeln('Content-Type: text/html; charset=utf-8');
    buffer.writeln();
    buffer.write(htmlBody);
    return buffer.toString();
  }

  /// Clear stored authentication state.
  Future<void> clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_senderEmailKey);
    await prefs.remove(_isAuthenticatedKey);
  }
}
