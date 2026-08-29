/// Local SMTP relay + password-reset server.
/// Run: dart run tools/smtp_server.dart
/// Needs env var APPWRITE_API_KEY (create in Appwrite Console > Settings > API Keys
/// with scopes: users.read + users.write). Without it, /reset-password will fail.
///
/// Endpoints:
///  POST http://localhost:8080/send-email      → forwards via Gmail SMTP
///  POST http://localhost:8080/reset-password  → updates Appwrite user password
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

const String smtpEmail = 'rohitft20@gmail.com';
const String appPassword = 'nrcppvuxywvttyvj';
const int port = 8080;

// Appwrite — project from appwrite_config.dart
const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
const String appwriteProjectId = '6a8c0d2c001da8c48b83';
// Set via: dart run tools/smtp_server.dart  (reads env)  OR  $env:APPWRITE_API_KEY="..."
// Create at: Appwrite Console > Settings > Overview > API Keys > Create (scopes: users.read, users.write)
String get appwriteApiKey =>
    Platform.environment['APPWRITE_API_KEY']?.trim() ?? '';

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('═══════════════════════════════════════════════');
  print('  Hari Om Traders — Local Relay Server');
  print('  Listening on http://localhost:$port');
  print('  Gmail SMTP: $smtpEmail');
  print('  Appwrite: $appwriteEndpoint  project=$appwriteProjectId');
  print('  API Key: ${appwriteApiKey.isEmpty ? "❌ NOT SET (set APPWRITE_API_KEY)" : "✅ set"}');
  print('═══════════════════════════════════════════════');
  print('');
  print('How to use:');
  print('  1. Keep this terminal open');
  print('  2. In another terminal: flutter run -d chrome');
  print('  3. Use Forgot Password — OTP + reset via this server');
  print('  If reset fails: create API key in Appwrite Console > Settings > API Keys');
  print('  then restart: \$env:APPWRITE_API_KEY="your_key"; dart run tools/smtp_server.dart');
  print('');

  await for (final request in server) {
    _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  request.response.headers.add('Access-Control-Allow-Origin', '*');
  request.response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
  request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method == 'OPTIONS') {
    request.response.statusCode = 200;
    await request.response.close();
    return;
  }

  final path = request.uri.path;
  if (request.method == 'POST' && path == '/send-email') {
    await _handleSendEmail(request);
    return;
  }
  if (request.method == 'POST' && path == '/reset-password') {
    await _handleResetPassword(request);
    return;
  }
  if (request.method == 'GET' && path == '/health') {
    request.response.write(jsonEncode({'ok': true, 'apiKeySet': appwriteApiKey.isNotEmpty}));
    await request.response.close();
    return;
  }

  request.response.statusCode = 404;
  request.response.write(jsonEncode({'success': false, 'error': 'Not found. POST /send-email or POST /reset-password'}));
  await request.response.close();
}

Future<void> _handleSendEmail(HttpRequest request) async {
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

    final report = await send(message, smtpServer).timeout(const Duration(seconds: 20));
    print('[Relay] ✅ Sent to $email → $report');
    request.response.write(jsonEncode({'success': true, 'message': 'Email sent to $email'}));
  } on MailerException catch (e) {
    final problems = e.problems.map((p) => '${p.code}: ${p.msg}').toList();
    print('[Relay] ❌ MailerException: $problems');
    request.response.write(jsonEncode({'success': false, 'error': 'SMTP error', 'problems': problems}));
  } catch (e) {
    print('[Relay] ❌ Error: $e');
    request.response.write(jsonEncode({'success': false, 'error': e.toString()}));
  }
  await request.response.close();
}

Future<void> _handleResetPassword(HttpRequest request) async {
  try {
    final body = jsonDecode(await utf8.decoder.bind(request).join());
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final newPassword = body['newPassword'] as String? ?? body['password'] as String? ?? '';

    if (email.isEmpty || !email.contains('@')) {
      request.response.statusCode = 400;
      request.response.write(jsonEncode({'success': false, 'error': 'Invalid email'}));
      await request.response.close();
      return;
    }
    if (newPassword.length < 8) {
      request.response.statusCode = 400;
      request.response.write(jsonEncode({'success': false, 'error': 'Password must be at least 8 characters'}));
      await request.response.close();
      return;
    }
    if (appwriteApiKey.isEmpty) {
      print('[Reset] ❌ APPWRITE_API_KEY not set');
      request.response.statusCode = 500;
      request.response.write(jsonEncode({
        'success': false,
        'error': 'Server not configured: APPWRITE_API_KEY missing. Create API key in Appwrite Console > Settings > API Keys (scopes: users.read, users.write) then restart server with \$env:APPWRITE_API_KEY="key"'
      }));
      await request.response.close();
      return;
    }

    print('[Reset] Looking up user by email: $email');
    // 1) Find user by email
    // Note: Appwrite v1.x+ expects JSON-encoded queries (matching Query.toString()).
    final listUri = Uri.parse(
        '$appwriteEndpoint/users?queries[]=${Uri.encodeComponent('{"method":"equal","attribute":"email","values":["$email"]}')}');
    final listRes = await http.get(listUri, headers: {
      'X-Appwrite-Project': appwriteProjectId,
      'X-Appwrite-Key': appwriteApiKey,
    });

    if (listRes.statusCode != 200) {
      print('[Reset] ❌ list users failed ${listRes.statusCode}: ${listRes.body}');
      request.response.statusCode = 500;
      request.response.write(jsonEncode({'success': false, 'error': 'Failed to lookup user: ${listRes.body}'}));
      await request.response.close();
      return;
    }

    final listJson = jsonDecode(listRes.body) as Map<String, dynamic>;
    final users = (listJson['users'] as List?) ?? [];
    // Fallback key is 'documents' for some SDKs — handle both
    final docs = users.isEmpty ? ((listJson['documents'] as List?) ?? []) : users;
    // Appwrite REST returns {total, users: []}
    final userList = users.isNotEmpty ? users : docs;
    if (userList.isEmpty) {
      print('[Reset] ❌ No user found for $email');
      request.response.statusCode = 404;
      request.response.write(jsonEncode({'success': false, 'error': 'No account found for $email'}));
      await request.response.close();
      return;
    }
    final userId = (userList.first as Map<String, dynamic>)['\$id'] as String;
    print('[Reset] Found userId=$userId, updating password...');

    // 2) Update password
    final patchUri = Uri.parse('$appwriteEndpoint/users/$userId/password');
    final patchRes = await http.patch(patchUri,
        headers: {
          'X-Appwrite-Project': appwriteProjectId,
          'X-Appwrite-Key': appwriteApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'password': newPassword}));

    if (patchRes.statusCode < 200 || patchRes.statusCode >= 300) {
      print('[Reset] ❌ update password failed ${patchRes.statusCode}: ${patchRes.body}');
      request.response.statusCode = 500;
      request.response.write(jsonEncode({'success': false, 'error': 'Failed to update password: ${patchRes.body}'}));
      await request.response.close();
      return;
    }

    print('[Reset] ✅ Password updated for $email ($userId)');
    request.response.write(jsonEncode({'success': true, 'message': 'Password reset successful. Please log in.'}));
  } catch (e, st) {
    print('[Reset] ❌ Exception: $e\n$st');
    request.response.statusCode = 500;
    request.response.write(jsonEncode({'success': false, 'error': e.toString()}));
  }
  await request.response.close();
}
