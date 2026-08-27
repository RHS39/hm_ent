import 'package:flutter/foundation.dart';

/// Simple email service abstraction.
/// On web/mobile without a real SMTP backend we log the verification link
/// and, if Appwrite is configured, could call an Appwrite Function.
/// For now this service queues the email (debugPrint) and returns true.
///
/// Replace `sendVerificationEmail` body with your preferred mailer:
/// - Appwrite Function + SMTP
/// - SendGrid / AWS SES via your backend
/// - `mailer` package on a Dart server
class EmailService {
  EmailService._();
  static final EmailService instance = EmailService._();

  /// Last sent verification link — exposed for tests and debug overlay.
  String? lastVerificationLink;
  String? lastRecipient;

  /// In-memory outbox for tests — stores {email, token, link}
  final List<Map<String, String>> outbox = [];

  /// Builds the verification URL used in the email.
  /// Example: https://hariomtraders.com/verify-email?token=YOUR_TOKEN
  /// On localhost/web the host is derived from [baseUrl] if provided.
  String buildVerificationLink(String token, {String? baseUrl}) {
    // Try to infer host from current Uri when on web; fallback to placeholder.
    // Caller can pass baseUrl = Uri.base.origin for accurate links on web.
    final base = baseUrl ?? 'https://hariomtraders.com';
    final clean = base.replaceAll(RegExp(r'/$'), '');
    return '$clean/verify-email?token=$token';
  }

  String _renderTemplate(String email, String link) {
    // Minimal HTML template — brand colors match Hari Om Traders theme
    return '''
<!DOCTYPE html>
<html>
  <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background:#F9FAFB; margin:0; padding:24px;">
    <div style="max-width:560px; margin:0 auto; background:#ffffff; border-radius:16px; overflow:hidden; border:1px solid #E5E7EB;">
      <div style="background:#0B0E0F; padding:20px 24px; color:#ffffff;">
        <div style="display:flex; align-items:center;">
          <span style="font-weight:800; font-size:18px; letter-spacing:-0.5px;">Hari Om Traders</span>
          <span style="margin-left:auto; background:#00C805; color:#fff; font-size:10px; font-weight:800; padding:4px 8px; border-radius:100px; letter-spacing:0.6px;">ORGANIC</span>
        </div>
      </div>
      <div style="padding:28px 24px;">
        <h1 style="margin:0 0 8px 0; font-size:20px; font-weight:800; color:#0B0E0F;">Confirm your subscription</h1>
        <p style="margin:0 0 16px 0; color:#6B7280; font-size:14px; line-height:1.6;">
          Hi — thanks for joining Hari Om Traders! Please confirm your email
          <strong style="color:#0B0E0F;">$email</strong> to start getting farm-fresh drops &amp; offers.<br/>
          This link expires in 24 hours.
        </p>
        <a href="$link" style="display:inline-block; background:#00C805; color:#ffffff; text-decoration:none; font-weight:800; font-size:14px; padding:12px 22px; border-radius:100px; margin-top:4px;">
          Verify email &rarr;
        </a>
        <p style="margin:16px 0 0 0; color:#9CA3AF; font-size:12px; line-height:1.5;">
          Button not working? Copy and paste this link:<br/>
          <a href="$link" style="color:#00A63E; word-break:break-all;">$link</a>
        </p>
      </div>
      <div style="padding:12px 24px; background:#F9FAFB; border-top:1px solid #E5E7EB; color:#9CA3AF; font-size:11px; text-align:center;">
        Hari Om Traders • Varanasi, UP 221313 • <a href="https://hariomtraders.com" style="color:#6B7280;">hariomtraders.com</a><br/>
        No spam. Unsubscribe anytime. Max 2× per month.
      </div>
    </div>
  </body>
</html>
''';
  }

  /// Queues/sends verification email.
  /// Returns true if queued/logged, false on failure.
  Future<bool> sendVerificationEmail({
    required String email,
    required String token,
    String? baseUrl,
  }) async {
    final normalized = email.trim().toLowerCase();
    final link = buildVerificationLink(token, baseUrl: baseUrl);
    lastVerificationLink = link;
    lastRecipient = normalized;
    outbox.add({'email': normalized, 'token': token, 'link': link});
    final html = _renderTemplate(normalized, link);
    // In production replace this with Appwrite Function call or SMTP.
    // For now we log so dev can click the link from console / debug overlay.
    debugPrint('[EmailService] Verification email queued for $normalized');
    debugPrint('[EmailService] Link: $link');
    // debugPrint(html); // uncomment to see full template
    // Simulate async send
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  void clear() {
    outbox.clear();
    lastVerificationLink = null;
    lastRecipient = null;
  }
}
