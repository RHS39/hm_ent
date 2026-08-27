import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'appwrite_config.dart';

/// Singleton Appwrite service — mirrors `SupabaseService` API style.
///
/// Call `AppwriteService.init()` in `main()` before `runApp()`.
/// All repositories use this via `AppwriteService.databases`, `.storage`, `.account`.
///
/// Web: automatically sets `selfSigned` = false for cloud endpoint;
/// self-hosted localhost may need `selfSigned: true`.
class AppwriteService {
  AppwriteService._();

  static Client? _client;
  static Databases? _databases;
  static Storage? _storage;
  static Account? _account;
  static bool _initialized = false;

  /// Initialize Appwrite. Safe to call even without real keys — skips if not configured.
  /// Returns true if ready to use.
  static Future<bool> init() async {
    if (!AppwriteConfig.isConfigured) {
      debugPrint('[Appwrite] Skipped init — set APPWRITE_PROJECT_ID / APPWRITE_ENDPOINT via --dart-define. '
          'Current $AppwriteConfig.debugInfo');
      return false;
    }
    try {
      _client = Client()
          .setEndpoint(AppwriteConfig.endpoint)
          .setProject(AppwriteConfig.projectId);

      // Enable self-signed for localhost dev only
      if (AppwriteConfig.endpoint.contains('localhost') || AppwriteConfig.endpoint.contains('127.0.0.1')) {
        _client = _client!.setSelfSigned(status: true);
      }

      _databases = Databases(_client!);
      _storage = Storage(_client!);
      _account = Account(_client!);
      _initialized = true;
      debugPrint('[Appwrite] Connected to ${AppwriteConfig.endpoint} project=${AppwriteConfig.projectId}');
      return true;
    } catch (e) {
      debugPrint('[Appwrite] Init failed: $e');
      return false;
    }
  }

  static bool get isInitialized => _initialized && _client != null;

  static Client get client {
    if (_client == null) throw StateError('Appwrite not initialized — call AppwriteService.init() first');
    return _client!;
  }

  static Databases get databases {
    if (_databases == null) throw StateError('Appwrite not initialized');
    return _databases!;
  }

  static Storage get storage {
    if (_storage == null) throw StateError('Appwrite not initialized');
    return _storage!;
  }

  static Account get account {
    if (_account == null) throw StateError('Appwrite not initialized');
    return _account!;
  }

  /// Convenience helpers matching SupabaseService shape
  static String get databaseId => AppwriteConfig.databaseId;
  static String get bucketId => AppwriteConfig.bucketId;
}
