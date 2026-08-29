import 'package:flutter/foundation.dart';
import 'gmail_service.dart';
import 'gmail_smtp_service.dart';
import 'mail_api_service.dart';

/// Purpose of the OTP email — controls subject + heading + body copy.
enum OtpEmailPurpose { signup, passwordReset }

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
    String? otpId,
    OtpEmailPurpose purpose = OtpEmailPurpose.passwordReset,
  }) async {
    final normalized = email.trim().toLowerCase();
    lastOtp = otp;
    lastRecipient = normalized;
    final html = _renderOtpTemplate(normalized, otp, otpId: otpId, purpose: purpose);

    debugPrint('[EmailService] sendOtpEmail → $normalized | purpose=$purpose | SMTP configured=${GmailSmtpService.instance.isConfigured} | MailApi configured=${MailApiService.instance.isConfigured} | Gmail OAuth signedIn=${GmailService.instance.isSignedIn}');

    final subject = purpose == OtpEmailPurpose.signup
        ? 'Verify your email — Hari Om Traders'
        : 'Your Password Reset OTP - Hari Om Traders';
    final textBody = purpose == OtpEmailPurpose.signup
        ? 'Your OTP ID: ${otpId ?? "N/A"} | Registration code: $otp (expires in 10 minutes). Enter this code to verify your email and complete registration.'
        : 'Your OTP ID: ${otpId ?? "N/A"} | OTP: $otp (expires in 10 minutes).';

    // 1) Preferred: Gmail SMTP via App Password (direct, no popup — mobile/desktop only)
    if (GmailSmtpService.instance.isConfigured) {
      try {
        debugPrint('[EmailService] Attempting Gmail SMTP send...');
        final sent = await GmailSmtpService.instance.sendEmail(
          to: normalized,
          subject: subject,
          htmlBody: html,
          textBody: textBody,
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
          subject: subject,
          htmlBody: html,
          textBody: textBody,
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
          subject: subject,
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
    debugPrint('[EmailService] OTP ID: ${otpId ?? "N/A"} | OTP for $normalized: $otp');
    debugPrint('[EmailService] (Web: mailer needs dart:io — configure MAIL_API_KEY for web)');
    debugPrint('[EmailService] (Desktop/mobile: check GMAIL_APP_PASSWORD / Gmail 2FA)');
    debugPrint('═══════════════════════════════════════════════');
    await Future.delayed(const Duration(milliseconds: 200));
    return false;
  }

  String _renderOtpTemplate(String email, String otp, {String? otpId, OtpEmailPurpose purpose = OtpEmailPurpose.passwordReset}) {
    // Premium, email-client-safe OTP template (table-based, no flex for Gmail/Outlook).
    // Purpose-aware copy: signup vs password reset.
    final isSignup = purpose == OtpEmailPurpose.signup;
    final title = isSignup ? 'Verify your email - Hari Om Traders' : 'Password Reset OTP - Hari Om Traders';
    final heading = isSignup ? 'Verify your email' : 'Password reset code';
    final introLine = isSignup
        ? 'Hi — use the code below to verify your email and complete your registration for'
        : 'Hi — use the code below to reset the password for';
    final ctaHint = isSignup
        ? 'Enter this code on the registration screen to verify your email and create your account.'
        : 'Enter this code on the password reset screen to create a new password.';
    final ignoreTitle = isSignup ? 'Didn&apos;t create an account?' : 'Didn&apos;t request this?';
    final ignoreBody = isSignup
        ? 'You can safely ignore this email — no account will be created.'
        : 'You can safely ignore this email — your password will not be changed. If you&apos;re concerned, please contact support.';
    return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
  </head>
  <body style="margin:0; padding:0; background:#F3F4F6; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
    <!-- Preheader (hidden preview text) -->
    <div style="display:none; max-height:0; overflow:hidden; mso-hide:all; font-size:1px; line-height:1px; color:#F3F4F6;">
      Your OTP is $otp — expires in 10 minutes.${otpId != null ? ' Reference ID: $otpId.' : ''} Do not share this code.
    </div>
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background:#F3F4F6;">
      <tr>
        <td align="center" style="padding:24px 16px;">
          <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:560px; background:#ffffff; border-radius:16px; border:1px solid #E5E7EB; overflow:hidden;">
            <!-- Header -->
            <tr>
              <td style="background:#0B0E0F; padding:18px 24px;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                  <tr>
                    <td align="left" style="font-weight:800; font-size:18px; letter-spacing:-0.4px; color:#ffffff; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">Hari Om Traders</td>
                    <td align="right"><span style="display:inline-block; background:#00C805; color:#ffffff; font-size:10px; font-weight:800; padding:5px 10px; border-radius:100px; letter-spacing:0.7px; line-height:1;">ORGANIC</span></td>
                  </tr>
                </table>
              </td>
            </tr>
            <!-- Body -->
            <tr>
              <td style="padding:28px 28px 24px 28px;">
                <h1 style="margin:0 0 10px 0; font-size:22px; font-weight:900; color:#0B0E0F; line-height:1.25; letter-spacing:-0.3px;">$heading</h1>
                <p style="margin:0 0 18px 0; color:#4B5563; font-size:14px; line-height:1.65;">
                  $introLine<br>
                  <span style="color:#0B0E0F; font-weight:700; word-break:break-all;">$email</span>
                </p>
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin:0 0 14px 0;">
                  <tr>
                    <td style="background:#FEF3C7; border:1px solid #FDE68A; border-radius:8px; padding:10px 14px; text-align:center; color:#92400E; font-size:13px; font-weight:600;">
                      &#9200; Expires in <strong style="color:#78350F;">10 minutes</strong> &nbsp;&bull;&nbsp; Do not share this code
                    </td>
                  </tr>
                </table>
                ${otpId != null ? '''
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin:0 0 14px 0; background:#F9FAFB; border:1px solid #E5E7EB; border-radius:10px;">
                  <tr>
                    <td style="padding:13px 16px; color:#6B7280; font-size:11px; font-weight:700; letter-spacing:0.7px; text-transform:uppercase; vertical-align:middle;">Reference ID</td>
                    <td align="right" style="padding:13px 16px; font-family:ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size:14px; font-weight:800; letter-spacing:3px; color:#6B7280; vertical-align:middle;">$otpId</td>
                  </tr>
                </table>''' : ''}
                <!-- OTP Code -->
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                  <tr>
                    <td align="center" style="background:#F0FDF4; border:2px dashed #00C805; border-radius:14px; padding:22px 16px;">
                      <div style="font-family:ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size:34px; font-weight:900; letter-spacing:12px; color:#0B0E0F; line-height:1; padding-left:12px;">$otp</div>
                      <div style="margin-top:10px; font-size:11px; font-weight:700; color:#059669; letter-spacing:0.8px; text-transform:uppercase;">One-time password &bull; Valid once</div>
                    </td>
                  </tr>
                </table>
                <p style="margin:18px 0 0 0; color:#6B7280; font-size:12px; line-height:1.6; text-align:center;">
                  $ctaHint
                </p>
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin:18px 0 0 0;">
                  <tr>
                    <td style="border-top:1px solid #F3F4F6; padding-top:16px; color:#9CA3AF; font-size:11px; line-height:1.6;">
                      <strong style="color:#6B7280;">$ignoreTitle</strong> $ignoreBody
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
            <!-- Footer -->
            <tr>
              <td style="background:#F9FAFB; border-top:1px solid #E5E7EB; padding:16px 24px; text-align:center;">
                <div style="color:#6B7280; font-size:12px; font-weight:700; letter-spacing:-0.2px;">Hari Om Traders</div>
                <div style="color:#9CA3AF; font-size:11px; line-height:1.5; margin-top:2px;">Varanasi, UP 221313 &bull; <a href="https://hariomtraders.com" style="color:#059669; text-decoration:none; font-weight:600;">hariomtraders.com</a></div>
                <div style="color:#9CA3AF; font-size:11px; margin-top:6px;">Need help? <a href="mailto:support@hariomtraders.com" style="color:#6B7280; text-decoration:underline;">support@hariomtraders.com</a></div>
              </td>
            </tr>
          </table>
          <div style="max-width:560px; margin:14px auto 0 auto; text-align:center; color:#9CA3AF; font-size:10px; line-height:1.5;">
            This is an automated message — please don&apos;t reply directly to this email.
          </div>
        </td>
      </tr>
    </table>
  </body>
</html>''';
  }

  void clear() {
    outbox.clear();
    lastVerificationLink = null;
    lastRecipient = null;
  }
}
