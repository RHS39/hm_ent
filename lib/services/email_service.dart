import 'package:flutter/foundation.dart';
import 'gmail_service.dart';
import 'gmail_smtp_service.dart';
import 'mail_api_service.dart';

/// Email service that uses Gmail API to send verification emails.
/// Falls back to debug logging when Gmail is not authenticated.
///
/// Gmail API requires OAuth setup in Google Cloud Console.
/// See gmail_service.dart for setup instructions.
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

  /// Sends verification email via Gmail SMTP (App Password) → Mail API → Gmail OAuth → debug fallback.
  /// Returns true if sent/logged, false on failure.
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

    // 1) Preferred: Gmail SMTP via App Password (no OAuth popup, works on mobile/desktop)
    if (GmailSmtpService.instance.isConfigured) {
      try {
        final sent = await GmailSmtpService.instance.sendEmail(
          to: normalized,
          subject: 'Verify your email - Hari Om Traders',
          htmlBody: html,
        );
        if (sent) {
          debugPrint('[EmailService] Verification email sent via Gmail SMTP to $normalized');
          return true;
        }
        debugPrint('[EmailService] Gmail SMTP failed, trying Mail API');
      } catch (e) {
        debugPrint('[EmailService] Gmail SMTP error: $e');
      }
    }

    // 2) Transactional Mail API (Resend/SendGrid/Brevo/Generic)
    if (MailApiService.instance.isConfigured) {
      try {
        final sent = await MailApiService.instance.sendEmail(
          to: normalized,
          subject: 'Verify your email - Hari Om Traders',
          htmlBody: html,
        );
        if (sent) {
          debugPrint('[EmailService] Verification email sent via Mail API to $normalized');
          return true;
        }
        debugPrint('[EmailService] Mail API send failed, trying Gmail OAuth');
      } catch (e) {
        debugPrint('[EmailService] Mail API error: $e');
      }
    }

    // 3) Gmail API if authenticated (OAuth popup)
    if (GmailService.instance.isSignedIn) {
      try {
        final sent = await GmailService.instance.sendEmail(
          to: normalized,
          subject: 'Verify your email - Hari Om Traders',
          htmlBody: html,
        );
        if (sent) {
          debugPrint('[EmailService] Verification email sent via Gmail OAuth to $normalized');
          return true;
        }
        debugPrint('[EmailService] Gmail send failed, falling back to debug log');
      } catch (e) {
        debugPrint('[EmailService] Gmail error: $e, falling back to debug log');
      }
    }

    // 4) Fallback: log to console for development (returns true so signup not blocked in dev)
    debugPrint('[EmailService] Verification email queued for $normalized');
    debugPrint('[EmailService] Link: $link');
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  /// Last OTP sent — exposed for debug overlay / tests.
  String? lastOtp;

  /// Sends OTP email via Gmail SMTP (App Password) → Mail API → Gmail OAuth → debug fallback.
  /// Gmail App Password is preferred for OTP when GMAIL_APP_PASSWORD is set.
  /// Returns false ONLY when a configured provider failed (SMTP/API). Returns true for
  /// debug/console fallback so the OTP flow is never blocked in development.
  Future<bool> sendOtpEmail({
    required String email,
    required String otp,
  }) async {
    final normalized = email.trim().toLowerCase();
    lastOtp = otp;
    lastRecipient = normalized;
    final html = _renderOtpTemplate(normalized, otp);

    debugPrint('[EmailService] sendOtpEmail → $normalized | SMTP configured=${GmailSmtpService.instance.isConfigured} | MailApi configured=${MailApiService.instance.isConfigured} | Gmail OAuth signedIn=${GmailService.instance.isSignedIn}');

    // 1) Preferred: Gmail SMTP via App Password (direct, no popup — mobile/desktop only)
    if (GmailSmtpService.instance.isConfigured) {
      try {
        debugPrint('[EmailService] Attempting Gmail SMTP send...');
        final sent = await GmailSmtpService.instance.sendEmail(
          to: normalized,
          subject: 'Your Password Reset OTP - Hari Om Traders',
          htmlBody: html,
          textBody: 'Your OTP for $normalized is $otp (expires in 10 minutes).',
        );
        if (sent) {
          debugPrint('[EmailService] ✅ OTP email sent via Gmail SMTP to $normalized');
          return true;
        }
        debugPrint('[EmailService] ❌ Gmail SMTP returned false — trying Mail API');
      } catch (e) {
        debugPrint('[EmailService] ❌ Gmail SMTP exception: $e');
      }
    } else {
      debugPrint('[EmailService] Gmail SMTP not available (web or not configured)');
    }

    // 2) Transactional Mail API (Resend/SendGrid/Brevo/Generic)
    if (MailApiService.instance.isConfigured) {
      try {
        debugPrint('[EmailService] Attempting Mail API send...');
        final sent = await MailApiService.instance.sendEmail(
          to: normalized,
          subject: 'Your Password Reset OTP - Hari Om Traders',
          htmlBody: html,
          textBody: 'Your OTP for $normalized is $otp (expires in 10 minutes).',
        );
        if (sent) {
          debugPrint('[EmailService] ✅ OTP email sent via Mail API to $normalized');
          return true;
        }
        debugPrint('[EmailService] ❌ Mail API send returned false');
      } catch (e) {
        debugPrint('[EmailService] ❌ Mail API exception: $e');
      }
    }

    // 3) Gmail OAuth — only try if already signed in (NO auto sign-in popup)
    if (GmailService.instance.isSignedIn) {
      try {
        debugPrint('[EmailService] Attempting Gmail OAuth send...');
        final sent = await GmailService.instance.sendEmail(
          to: normalized,
          subject: 'Your Password Reset OTP - Hari Om Traders',
          htmlBody: html,
        );
        if (sent) {
          debugPrint('[EmailService] ✅ OTP email sent via Gmail OAuth to $normalized');
          return true;
        }
        debugPrint('[EmailService] ❌ Gmail OAuth send returned false');
      } catch (e) {
        debugPrint('[EmailService] ❌ Gmail OAuth exception: $e');
      }
    }

    // 4) No provider sent the email — return false so caller knows email was NOT delivered.
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('[EmailService] ❌ NO EMAIL PROVIDER SENT THE OTP');
    debugPrint('[EmailService] OTP for $normalized: $otp');
    debugPrint('[EmailService] (Web: mailer needs dart:io — configure MAIL_API_KEY for web)');
    debugPrint('[EmailService] (Desktop/mobile: check GMAIL_APP_PASSWORD / Gmail 2FA)');
    debugPrint('═══════════════════════════════════════════════');
    await Future.delayed(const Duration(milliseconds: 200));
    return false;
  }

  String _renderOtpTemplate(String email, String otp) {
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
        <h1 style="margin:0 0 8px 0; font-size:20px; font-weight:800; color:#0B0E0F;">Password Reset OTP</h1>
        <p style="margin:0 0 16px 0; color:#6B7280; font-size:14px; line-height:1.6;">
          Hi — use the code below to reset your password for
          <strong style="color:#0B0E0F;">$email</strong>.<br/>
          This code expires in <strong>10 minutes</strong>.
        </p>
        <div style="background:#F9FAFB; border:2px dashed #00C805; border-radius:12px; padding:20px; text-align:center; margin:8px 0;">
          <span style="font-size:36px; font-weight:900; letter-spacing:10px; color:#0B0E0F; font-family:monospace;">$otp</span>
        </div>
        <p style="margin:16px 0 0 0; color:#9CA3AF; font-size:12px; line-height:1.5;">
          If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.
        </p>
      </div>
      <div style="padding:12px 24px; background:#F9FAFB; border-top:1px solid #E5E7EB; color:#9CA3AF; font-size:11px; text-align:center;">
        Hari Om Traders &bull; Varanasi, UP 221313 &bull; <a href="https://hariomtraders.com" style="color:#6B7280;">hariomtraders.com</a><br/>
        No spam. Unsubscribe anytime. Max 2&times; per month.
      </div>
    </div>
  </body>
</html>''';
  }

  void clear() {
    outbox.clear();
    lastVerificationLink = null;
    lastRecipient = null;
  }
}
