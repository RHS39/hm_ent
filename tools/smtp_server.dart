/// Local SMTP relay server — sends email via Gmail SMTP.
/// Run: dart run tools/smtp_server.dart
/// Then run Flutter app: flutter run -d chrome
///
/// The Flutter web app calls http://localhost:8080/send-email
/// This server forwards it via Gmail SMTP (where dart:io is available).
import 'dart:convert';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

const String smtpEmail = 'rohitft20@gmail.com';
const String appPassword = 'nrcppvuxywvttyvj';
const int port = 8080;

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('═══════════════════════════════════════════════');
  print('  Hari Om Traders — Local SMTP Relay Server');
  print('  Listening on http://localhost:$port');
  print('  Gmail SMTP: $smtpEmail');
  print('═══════════════════════════════════════════════');
  print('');
  print('How to use:');
  print('  1. Keep this terminal open');
  print('  2. In another terminal: flutter run -d chrome');
  print('  3. Use Forgot Password — OTP email will be sent via this server');
  print('');

  await for (final request in server) {
    _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  // CORS headers
  request.response.headers.add('Access-Control-Allow-Origin', '*');
  request.response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
  request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method == 'OPTIONS') {
    request.response.statusCode = 200;
    await request.response.close();
    return;
  }

  if (request.method != 'POST' || request.uri.path != '/send-email') {
    request.response.statusCode = 404;
    request.response.write(jsonEncode({'error': 'Not found. POST /send-email'}));
    await request.response.close();
    return;
  }

  try {
    final body = jsonDecode(await utf8.decoder.bind(request).join());
    final email = body['email'] as String? ?? '';
    final subject = body['subject'] as String? ?? 'Hari Om Traders';
    final html = body['html'] as String? ?? '';
    final text = body['text'] as String? ?? '';

    if (email.isEmpty || !email.contains('@')) {
      request.response.statusCode = 400;
      request.response.write(jsonEncode({'success': false, 'error': 'Invalid email'}));
      await request.response.close();
      return;
    }

    print('[Relay] Sending OTP email to $email...');

    final smtpServer = gmail(smtpEmail, appPassword);
    final message = Message()
      ..from = Address(smtpEmail, 'Hari Om Traders')
      ..recipients.add(email)
      ..subject = subject
      ..html = html
      ..text = text;

    final report = await send(message, smtpServer);
    print('[Relay] ✅ Sent to $email → $report');

    request.response.write(jsonEncode({
      'success': true,
      'message': 'Email sent to $email',
    }));
  } on MailerException catch (e) {
    final problems = e.problems.map((p) => '${p.code}: ${p.msg}').toList();
    print('[Relay] ❌ MailerException: $problems');
    request.response.write(jsonEncode({
      'success': false,
      'error': 'SMTP error',
      'problems': problems,
    }));
  } catch (e) {
    print('[Relay] ❌ Error: $e');
    request.response.write(jsonEncode({
      'success': false,
      'error': e.toString(),
    }));
  }

  await request.response.close();
}
