/// Appwrite Cloud Function — Reset Password via Management API.
///
/// Deploy in Appwrite Console > Functions:
///   1. Create function (runtime: Dart / Node 18 / any)
///   2. Paste this as the source (main.dart or index.js)
///   3. Set env var APPWRITE_API_KEY with users.read + users.write scopes
///   4. Set permissions: Execute → Any (no auth needed for password reset)
///   5. Note the function ID — pass via --dart-define=RESET_FUNCTION_ID=xxx
///
/// Request body (JSON):
///   { "email": "user@example.com", "newPassword": "Ta12345678@" }
///
/// Response (JSON):
///   { "success": true, "message": "Password updated" }
///   { "success": false, "error": "User not found" }
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
  print('[ResetPassword] listening on :3000');

  await for (final request in server) {
    _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  request.response.headers.add('Access-Control-Allow-Origin', '*');
  request.response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
  request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method == 'OPTIONS') {
    request.response.statusCode = 200;
    await request.response.close();
    return;
  }

  if (request.method == 'POST' && request.uri.path == '/reset-password') {
    await _handleReset(request);
    return;
  }

  request.response.statusCode = 404;
  request.response.write(jsonEncode({'success': false, 'error': 'Not found'}));
  await request.response.close();
}

Future<void> _handleReset(HttpRequest request) async {
  try {
    final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final newPassword = body['newPassword'] as String? ?? '';

    if (email.isEmpty || !email.contains('@')) {
      _jsonError(request, 400, 'Invalid email');
      return;
    }
    if (newPassword.length < 8) {
      _jsonError(request, 400, 'Password must be at least 8 characters');
      return;
    }

    final endpoint = Platform.environment['APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1';
    final projectId = Platform.environment['APPWRITE_PROJECT_ID'] ?? '';
    final apiKey = Platform.environment['APPWRITE_API_KEY'] ?? '';

    if (projectId.isEmpty || apiKey.isEmpty) {
      _jsonError(request, 500, 'Server not configured: APPWRITE_PROJECT_ID or APPWRITE_API_KEY missing');
      return;
    }

    // 1) Find user by email via Management API
    // Note: Appwrite v1.x+ expects JSON-encoded queries (matching Query.toString()).
    final listUri = Uri.parse('$endpoint/users?queries[]=${Uri.encodeComponent('{"method":"equal","attribute":"email","values":["$email"]}')}');
    final listRes = await httpGet(listUri, headers: {
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    });

    if (listRes.statusCode != 200) {
      _jsonError(request, 500, 'Failed to query users: ${listRes.body}');
      return;
    }

    final listJson = jsonDecode(listRes.body) as Map<String, dynamic>;
    final users = (listJson['users'] as List?) ?? [];
    if (users.isEmpty) {
      _jsonError(request, 404, 'No account found for $email');
      return;
    }

    final userId = (users.first as Map<String, dynamic>)['\$id'] as String;
    print('[Reset] Found userId=$userId for $email');

    // 2) Update password via Management API
    final patchUri = Uri.parse('$endpoint/users/$userId/password');
    final patchRes = await httpPatch(patchUri, headers: {
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
      'Content-Type': 'application/json',
    }, body: jsonEncode({'password': newPassword}));

    if (patchRes.statusCode < 200 || patchRes.statusCode >= 300) {
      _jsonError(request, 500, 'Failed to update password: ${patchRes.body}');
      return;
    }

    print('[Reset] ✅ Password updated for $email ($userId)');
    request.response.write(jsonEncode({'success': true, 'message': 'Password updated successfully'}));
  } catch (e, st) {
    print('[Reset] ❌ $e\n$st');
    _jsonError(request, 500, e.toString());
  }
  await request.response.close();
}

void _jsonError(HttpRequest request, int code, String msg) {
  request.response.statusCode = code;
  request.response.write(jsonEncode({'success': false, 'error': msg}));
}

// Minimal HTTP helpers using dart:io HttpClient
Future<HttpResponse> httpGet(Uri url, {Map<String, String>? headers}) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(url);
    headers?.forEach((k, v) => req.headers.set(k, v));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    return _FakeResponse(res.statusCode, body);
  } finally {
    client.close();
  }
}

Future<HttpResponse> httpPatch(Uri url, {Map<String, String>? headers, Object? body}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl('PATCH', url);
    headers?.forEach((k, v) => req.headers.set(k, v));
    if (body != null) req.write(body);
    final res = await req.close();
    final resBody = await res.transform(utf8.decoder).join();
    return _FakeResponse(res.statusCode, resBody);
  } finally {
    client.close();
  }
}

class HttpResponse {
  final int statusCode;
  final String body;
  HttpResponse(this.statusCode, this.body);
}

class _FakeResponse extends HttpResponse {
  _FakeResponse(super.statusCode, super.body);
}
