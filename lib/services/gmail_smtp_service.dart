import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../appwrite/appwrite_config.dart';

/// Gmail SMTP via App Password (no OAuth popup).
///
/// Uses `smtp.gmail.com:587` with STARTTLS. App Password must be generated
/// at https://myaccount.google.com/apppasswords (2-Step Verification required).
///
/// Config via --dart-define (preferred) or default dev password:
///   --dart-define=GMAIL_SMTP_EMAIL=you@gmail.com
///   --dart-define=GMAIL_APP_PASSWORD="nrcp pvux ywvt tyvj"
///
/// If [AppwriteConfig.gmailAppPasswordSanitized] is set, this service is tried
/// FIRST for OTP (before MailApi / Gmail OAuth). On web it auto-fails over
/// to MailApi because `mailer` needs dart:io.
class GmailSmtpService {
  GmailSmtpService._();
  static final GmailSmtpService instance = GmailSmtpService._();

  bool get isConfigured => AppwriteConfig.isGmailSmtpConfigured && !kIsWeb;

  /// Send HTML email via Gmail SMTP.
  /// Returns true on success, false on failure.
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) async {
    if (kIsWeb) {
      debugPrint('[GmailSmtp] ❌ Not supported on web — mailer needs dart:io. Configure MAIL_API_KEY for web support.');
      return false;
    }
    if (!AppwriteConfig.isGmailSmtpConfigured) {
      debugPrint('[GmailSmtp] ❌ Not configured — set --dart-define=GMAIL_SMTP_EMAIL and GMAIL_APP_PASSWORD');
      return false;
    }
    final smtpEmail = AppwriteConfig.effectiveGmailSmtpEmail;
    final appPassword = AppwriteConfig.gmailAppPasswordSanitized;
    debugPrint('[GmailSmtp] Sending to $to via $smtpEmail (port 587, STARTTLS)');
    try {
      final smtpServer = gmail(smtpEmail, appPassword);
      final message = Message()
        ..from = Address(smtpEmail, AppwriteConfig.mailFromName)
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlBody
        ..text = textBody ?? _stripHtml(htmlBody);

      final sendReport = await send(message, smtpServer);
      debugPrint('[GmailSmtp] ✅ Sent to $to → $sendReport');
      return true;
    } on MailerException catch (e) {
      debugPrint('[GmailSmtp] ❌ MailerException to $to:');
      for (final p in e.problems) {
        debugPrint('[GmailSmtp]   ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      debugPrint('[GmailSmtp] ❌ Exception to $to: $e');
      return false;
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
