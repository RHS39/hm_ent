/// Automated Appwrite provisioning for Hari Om Traders.
/// Creates: database, 3 collections, attributes, indexes, and storage bucket.
///
/// Usage:
///   1. Create API Key in Appwrite Console: Project → Settings → API Keys
///      Scopes: databases.write, collections.write, attributes.write, indexes.write, buckets.write, documents.write
///   2. Set env vars and run:
///      APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
///      APPWRITE_PROJECT_ID=xxx
///      APPWRITE_API_KEY=xxx
///      dart run appwrite/setup_appwrite.dart
///
/// Or pass as args: dart run appwrite/setup_appwrite.dart --endpoint=... --projectId=... --apiKey=...
/// Requires: `dart pub add http` (already via appwrite dep, but http is available).
import 'dart:convert';
import 'dart:io';

const String kDatabaseId = 'hari_om_db';
const String kDatabaseName = 'Hari Om DB';

const String kProductsId = 'products';
const String kSubscribersId = 'subscribers';
const String kContactsId = 'contact_messages';
const String kUsersId = 'users';
const String kPendingSubscriptionsId = 'pending_subscriptions';
const String kBucketId = 'product-images';

Future<void> main(List<String> args) async {
  final env = Platform.environment;
  String endpoint = _arg(args, 'endpoint') ?? env['APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1';
  String projectId = _arg(args, 'projectId') ?? env['APPWRITE_PROJECT_ID'] ?? '';
  String apiKey = _arg(args, 'apiKey') ?? env['APPWRITE_API_KEY'] ?? '';

  if (projectId.isEmpty || apiKey.isEmpty) {
    print('Missing APPWRITE_PROJECT_ID or APPWRITE_API_KEY.\n');
    print('Usage: dart run appwrite/setup_appwrite.dart --projectId=xxx --apiKey=xxx');
    print('   or set env: APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, APPWRITE_API_KEY');
    print('\nGet API Key: Appwrite Console → Project → Settings → API Keys → Create');
    print('Needed scopes: databases.write, collections.write, attributes.write, indexes.write, buckets.write');
    exit(1);
  }
  endpoint = endpoint.replaceAll(RegExp(r'/$'), '');
  // Normalize: endpoint may be https://cloud.appwrite.io/v1 — strip trailing /v1 for dedup handling
  String buildUrl(String path) {
    if (endpoint.endsWith('/v1') && path.startsWith('/v1')) {
      return '${endpoint}${path.substring(3)}'; // avoid /v1/v1
    }
    if (!endpoint.endsWith('/v1') && !path.startsWith('/v1')) {
      return '$endpoint/v1$path';
    }
    return '$endpoint$path';
  }

  final client = HttpClient();
  // Helper
  Future<Map<String, dynamic>?> req(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse(buildUrl(path));
    final request = await client.openUrl(method, uri);
    request.headers.set('X-Appwrite-Project', projectId);
    request.headers.set('X-Appwrite-Key', apiKey);
    request.headers.set('Content-Type', 'application/json');
    if (body != null) request.write(jsonEncode(body));
    final resp = await request.close();
    final text = await resp.transform(utf8.decoder).join();
    final ok = resp.statusCode >= 200 && resp.statusCode < 300;
    dynamic json;
    try { json = text.isNotEmpty ? jsonDecode(text) : null; } catch (_) { json = text; }
    if (ok) {
      print('✓ $method $path → ${resp.statusCode}');
      return json is Map<String, dynamic> ? json : {'result': json};
    } else {
      // 409 = already exists — treat as ok
      if (resp.statusCode == 409) {
        print('• $method $path → 409 already exists (skip)');
        return null;
      }
      print('✗ $method $path → ${resp.statusCode}: $text');
      return null;
    }
  }

  print('Appwrite Setup → $endpoint project=$projectId\n');

  // 1. Database
  await req('POST', '/v1/databases', body: {'databaseId': kDatabaseId, 'name': kDatabaseName});

  // 2. Collections
  Future<void> createCollection(String id, String name, List<String> permissions) async {
    await req('POST', '/v1/databases/$kDatabaseId/collections', body: {
      'collectionId': id,
      'name': name,
      'permissions': permissions,
      'documentSecurity': true,
    });
  }

  // products: public read, users write (harden to team:admin later)
  await createCollection(kProductsId, 'Products', ['read("any")', 'create("users")', 'update("users")', 'delete("users")']);
  await createCollection(kSubscribersId, 'Subscribers', ['create("any")', 'read("users")', 'update("users")', 'delete("users")']);
  await createCollection(kContactsId, 'Contact Messages', ['create("any")', 'read("users")', 'update("users")', 'delete("users")']);
  await createCollection(kUsersId, 'Users', ['read("users")', 'create("users")', 'update("users")', 'delete("users")']);
  // pending_subscriptions: holds unverified emails + token, 24h expiry — any can create (Join form), users can read/update
  await createCollection(kPendingSubscriptionsId, 'Pending Subscriptions', ['create("any")', 'read("any")', 'update("any")', 'delete("any")']);

  // Helper to add attributes
  Future<void> attr(String col, String path, Map<String, dynamic> body) async {
    final res = await req('POST', '/v1/databases/$kDatabaseId/collections/$col/attributes$path', body: body);
    // Appwrite attributes are async — wait 500ms between each
    await Future.delayed(const Duration(milliseconds: 600));
    if (res == null) {
      // poll until available?
    }
  }

  print('\n— Creating attributes: products —');
  await attr(kProductsId, '/string', {'key': 'product_id', 'size': 32, 'required': true});
  await attr(kProductsId, '/string', {'key': 'name', 'size': 128, 'required': true});
  await attr(kProductsId, '/float', {'key': 'price', 'required': true, 'min': 0});
  await attr(kProductsId, '/string', {'key': 'description', 'size': 1000, 'required': false, 'default': ''});
  await attr(kProductsId, '/string', {'key': 'icon', 'size': 32, 'required': false, 'default': 'spa'});
  await attr(kProductsId, '/string', {'key': 'category', 'size': 32, 'required': false, 'default': 'Jaggery'});
  await attr(kProductsId, '/integer', {'key': 'stock_quantity', 'required': false, 'min': 0, 'max': 1000000, 'default': 100});
  await attr(kProductsId, '/integer', {'key': 'moq', 'required': false, 'min': 1, 'max': 999, 'default': 2});
  await attr(kProductsId, '/string', {'key': 'image_url', 'size': 500, 'required': false});
  await attr(kProductsId, '/string', {'key': 'image_2', 'size': 500, 'required': false});
  await attr(kProductsId, '/string', {'key': 'image_3', 'size': 500, 'required': false});
  await attr(kProductsId, '/boolean', {'key': 'is_active', 'required': false, 'default': true});

  print('\n— Creating indexes: products —');
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kProductsId/indexes', body: {'key': 'idx_product_id', 'type': 'unique', 'attributes': ['product_id']});
  await Future.delayed(const Duration(milliseconds: 400));
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kProductsId/indexes', body: {'key': 'idx_name', 'type': 'unique', 'attributes': ['name']});
  await Future.delayed(const Duration(milliseconds: 400));
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kProductsId/indexes', body: {'key': 'idx_category', 'type': 'key', 'attributes': ['category']});

  print('\n— Creating attributes: subscribers —');
  await attr(kSubscribersId, '/string', {'key': 'email', 'size': 255, 'required': true});
  await attr(kSubscribersId, '/string', {'key': 'status', 'size': 32, 'required': false, 'default': 'active'});
  await attr(kSubscribersId, '/datetime', {'key': 'subscribed_at', 'required': true});
  await attr(kSubscribersId, '/datetime', {'key': 'updated_at', 'required': true});
  await attr(kSubscribersId, '/string', {'key': 'source', 'size': 64, 'required': false, 'default': 'home_newsletter'});
  await attr(kSubscribersId, '/string', {'key': 'meta', 'size': 2000, 'required': false, 'default': '{}'});

  print('\n— Creating indexes: subscribers —');
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kSubscribersId/indexes', body: {'key': 'idx_email', 'type': 'unique', 'attributes': ['email']});
  await Future.delayed(const Duration(milliseconds: 400));
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kSubscribersId/indexes', body: {'key': 'idx_status', 'type': 'key', 'attributes': ['status']});

  print('\n— Creating attributes: contact_messages —');
  await attr(kContactsId, '/string', {'key': 'name', 'size': 128, 'required': true});
  await attr(kContactsId, '/string', {'key': 'email', 'size': 255, 'required': true});
  await attr(kContactsId, '/string', {'key': 'phone', 'size': 32, 'required': true});
  await attr(kContactsId, '/string', {'key': 'address', 'size': 500, 'required': true});
  await attr(kContactsId, '/string', {'key': 'pincode', 'size': 16, 'required': true});
  await attr(kContactsId, '/string', {'key': 'district', 'size': 64, 'required': true});
  await attr(kContactsId, '/string', {'key': 'state', 'size': 64, 'required': true});
  await attr(kContactsId, '/string', {'key': 'country', 'size': 64, 'required': false, 'default': 'India'});
  await attr(kContactsId, '/string', {'key': 'message', 'size': 2000, 'required': true});
  await attr(kContactsId, '/string', {'key': 'source', 'size': 64, 'required': false, 'default': 'contact_us_page'});
  await attr(kContactsId, '/string', {'key': 'status', 'size': 32, 'required': false, 'default': 'new'});

  print('\n— Creating attributes: pending_subscriptions —');
  await attr(kPendingSubscriptionsId, '/string', {'key': 'email', 'size': 255, 'required': true});
  await attr(kPendingSubscriptionsId, '/string', {'key': 'verification_token', 'size': 64, 'required': true});
  await attr(kPendingSubscriptionsId, '/datetime', {'key': 'expires_at', 'required': true});
  await attr(kPendingSubscriptionsId, '/datetime', {'key': 'created_at', 'required': true});
  await attr(kPendingSubscriptionsId, '/string', {'key': 'source', 'size': 64, 'required': false, 'default': 'home_newsletter'});

  print('\n— Creating indexes: pending_subscriptions —');
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kPendingSubscriptionsId/indexes', body: {'key': 'idx_pending_email', 'type': 'unique', 'attributes': ['email']});
  await Future.delayed(const Duration(milliseconds: 400));
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kPendingSubscriptionsId/indexes', body: {'key': 'idx_pending_token', 'type': 'unique', 'attributes': ['verification_token']});
  await Future.delayed(const Duration(milliseconds: 400));
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kPendingSubscriptionsId/indexes', body: {'key': 'idx_pending_expires', 'type': 'key', 'attributes': ['expires_at']});

  print('\n— Creating attributes: users —');
  await attr(kUsersId, '/string', {'key': 'userId', 'size': 64, 'required': true});
  await attr(kUsersId, '/string', {'key': 'name', 'size': 128, 'required': true});
  await attr(kUsersId, '/string', {'key': 'email', 'size': 255, 'required': true});
  await attr(kUsersId, '/string', {'key': 'phone', 'size': 32, 'required': false});
  await attr(kUsersId, '/string', {'key': 'role', 'size': 32, 'required': false, 'default': 'user'});
  await attr(kUsersId, '/string', {'key': 'privileges', 'size': 2000, 'required': false, 'default': '[]'});
  await attr(kUsersId, '/string', {'key': 'status', 'size': 32, 'required': false, 'default': 'active'});
  await attr(kUsersId, '/boolean', {'key': 'emailVerification', 'required': false, 'default': false});
  await attr(kUsersId, '/boolean', {'key': 'phoneVerification', 'required': false, 'default': false});

  print('\n— Creating indexes: users —');
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kUsersId/indexes', body: {'key': 'idx_userId', 'type': 'unique', 'attributes': ['userId']});
  await Future.delayed(const Duration(milliseconds: 400));
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kUsersId/indexes', body: {'key': 'idx_users_email', 'type': 'unique', 'attributes': ['email']});
  await Future.delayed(const Duration(milliseconds: 400));
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kUsersId/indexes', body: {'key': 'idx_users_role', 'type': 'key', 'attributes': ['role']});
  await Future.delayed(const Duration(milliseconds: 400));
  await req('POST', '/v1/databases/$kDatabaseId/collections/$kUsersId/indexes', body: {'key': 'idx_users_status', 'type': 'key', 'attributes': ['status']});

  print('\n— Creating bucket: $kBucketId —');
  await req('POST', '/v1/storage/buckets', body: {
    'bucketId': kBucketId,
    'name': 'Product Images',
    'permissions': ['read("any")', 'create("users")', 'update("users")', 'delete("users")'],
    'fileSecurity': true,
    'enabled': true,
    'maximumFileSize': 5242880,
    'allowedFileExtensions': ['jpg', 'jpeg', 'png', 'webp', 'gif'],
  });

  print('\nDone! Next:');
  print('  - Wait ~5s for attributes to become "available" (Appwrite processes async)');
  print('  - Run: flutter run --dart-define=APPWRITE_PROJECT_ID=$projectId --dart-define=APPWRITE_ENDPOINT=$endpoint');
  print('  - Seed: call AppwriteProductRepository.seedDemoProducts() once');
  client.close();
}

String? _arg(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('--$name=')) return a.substring('--$name='.length);
  }
  return null;
}
