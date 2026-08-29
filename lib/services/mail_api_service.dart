import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../appwrite/appwrite_config.dart';

/// Server-side transactional email via HTTP API.
///
/// Supports Resend, SendGrid, Brevo, Generic webhook, and Appwrite Functions
/// based on [AppwriteConfig.mailProvider] / [mailApiUrl].
///
/// All secrets come from --dart-define so nothing is committed:
///   flutter run --dart-define=MAIL_PROVIDER=resend
///               --dart-define=MAIL_API_KEY=re_xxx
///               --dart-define=MAIL_API_URL=https://api.resend.com/emails
///               --dart-define=MAIL_FROM_EMAIL=noreply@hariomtraders.com
///               --dart-define=MAIL_FROM_NAME=Hari Om Traders
///
/// Priority: this service is tried FIRST in EmailService before Gmail OAuth.
class MailApiService {
  MailApiService._();
  static final MailApiService instance = MailApiService._();

  bool get isConfigured => AppwriteConfig.isMailApiConfigured;

  String get _provider {
    final p = AppwriteConfig.mailProvider.trim().toLowerCase();
    if (p != 'auto' && p.isNotEmpty) return p;
    // Auto-detect from URL
    final url = AppwriteConfig.mailApiUrl.toLowerCase();
    if (url.contains('resend')) return 'resend';
    if (url.contains('sendgrid')) return 'sendgrid';
    if (url.contains('brevo') || url.contains('sendinblue')) return 'brevo';
    if (url.contains('/functions/')) return 'appwrite_function';
    return 'generic';
  }

  /// Send HTML email via configured provider.
  /// Returns true on 2xx.
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) async {
    if (!isConfigured) {
      debugPrint('[MailApi] not configured — skip (set MAIL_API_KEY/MAIL_API_URL)');
      return false;
    }
    final url = AppwriteConfig.mailApiUrl;
    final apiKey = AppwriteConfig.mailApiKey;
    final fromEmail = AppwriteConfig.mailFromEmail;
    final fromName = AppwriteConfig.mailFromName;
    final provider = _provider;

    try {
      late http.Response res;
      switch (provider) {
        case 'resend':
          res = await http.post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'from': '$fromName <$fromEmail>',
              'to': [to],
              'subject': subject,
              'html': htmlBody,
              if (textBody != null) 'text': textBody,
            }),
          );
          break;

        case 'sendgrid':
          res = await http.post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'personalizations': [
                {
                  'to': [
                    {'email': to}
                  ],
                  'subject': subject,
                }
              ],
              'from': {'email': fromEmail, 'name': fromName},
              'subject': subject,
              'content': [
                {'type': 'text/html', 'value': htmlBody}
              ],
            }),
          );
          break;

        case 'brevo':
          // Brevo (ex-Sendinblue) — api-key header, not Bearer
          res = await http.post(
            Uri.parse(url),
            headers: {
              'api-key': apiKey,
              'Content-Type': 'application/json',
              'accept': 'application/json',
            },
            body: jsonEncode({
              'sender': {'email': fromEmail, 'name': fromName},
              'to': [
                {'email': to}
              ],
              'subject': subject,
              'htmlContent': htmlBody,
            }),
          );
          break;

        case 'appwrite_function':
          // Appwrite Function execution — POST body as JSON.
          // Function receives { email, subject, html, text } in req.body.
          res = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'X-Appwrite-Project': AppwriteConfig.projectId,
              if (apiKey.isNotEmpty) 'X-Appwrite-Key': apiKey,
            },
            body: jsonEncode({
              'email': to,
              'to': to,
              'subject': subject,
              'html': htmlBody,
              'text': textBody,
            }),
          );
          break;

        case 'generic':
        default:
          // Generic webhook — {to, subject, html, text, fromEmail, fromName}
          res = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'to': to,
              'email': to,
              'subject': subject,
              'html': htmlBody,
              'htmlBody': htmlBody,
              if (textBody != null) 'text': textBody,
              'from': fromEmail,
              'fromEmail': fromEmail,
              'fromName': fromName,
            }),
          );
          break;
      }

      final ok = res.statusCode >= 200 && res.statusCode < 300;
      if (ok) {
        debugPrint('[MailApi/$provider] sent to $to (${res.statusCode})');
        return true;
      }
      debugPrint('[MailApi/$provider] failed ${res.statusCode}: ${res.body.length > 500 ? res.body.substring(0, 500) : res.body}');
      return false;
    } catch (e) {
      debugPrint('[MailApi/$provider] exception: $e');
      return false;
    }
  }
}
