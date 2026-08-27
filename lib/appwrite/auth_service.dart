import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'appwrite_client.dart';

/// Global notifier for Appwrite user — mirrors Supabase `authUserNotifier`.
final ValueNotifier<models.User?> appwriteUserNotifier = ValueNotifier<models.User?>(null);
final ValueNotifier<models.Session?> appwriteSessionNotifier = ValueNotifier<models.Session?>(null);

/// Admin emails that bypass normal flow and are treated as admin.
const List<String> appwriteAdminEmails = [
  'admin@hariomtraders.com',
  'mahadevft6@gmail.com',
  'demo@hariomtraders.com',
];
const String appwriteAdminPassword = 'HariOm@2026';

const String appwriteDummyCustomerEmail = 'customer@hariomtraders.com';
const String appwriteDummyCustomerPassword = 'HariOm@2026';

/// Appwrite Auth service.
///
/// Uses Appwrite `Account` (email/password) + local session storage.
/// Supports: signUp, signIn, signOut, sendPasswordReset, currentUser, isAdmin,
/// plus demo-admin bypass (local, no server) matching Supabase dummy mode.
class AppwriteAuthService {
  static models.User? _demoUser;
  static bool get isDemoAdmin => _demoUser != null;

  /// Initialize — fetch current session/user if already logged in.
  static Future<void> initListener() async {
    if (!AppwriteService.isInitialized) return;
    try {
      final user = await AppwriteService.account.get();
      appwriteUserNotifier.value = user;
      debugPrint('[AppwriteAuth] restored session: ${user.email}');
    } catch (_) {
      appwriteUserNotifier.value = _demoUser;
      debugPrint('[AppwriteAuth] no active session');
    }
  }

  static models.User? get currentUser => _demoUser ?? appwriteUserNotifier.value;

  static bool get isLoggedIn => currentUser != null;

  static bool get isAdmin {
    final u = currentUser;
    if (u == null) return false;
    final email = u.email.toLowerCase().trim();
    return appwriteAdminEmails.contains(email) || _demoUser != null;
  }

  static String get displayName {
    final u = currentUser;
    if (u == null) return '';
    final name = u.name.trim();
    if (name.isNotEmpty) return name;
    return u.email.split('@').first;
  }

  static String get displayEmail => currentUser?.email ?? '';

  // ── Sign Up ──
  static Future<({bool ok, String message})> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');
    try {
      final user = await AppwriteService.account.create(
        userId: ID.unique(),
        email: email.trim(),
        password: password,
        name: name.trim(),
      );
      // Auto sign in after sign up
      await AppwriteService.account.createEmailPasswordSession(email: email.trim(), password: password);
      final me = await AppwriteService.account.get();
      appwriteUserNotifier.value = me;
      debugPrint('[AppwriteAuth] signUp ok: ${user.email}');
      return (ok: true, message: 'Account created!');
    } on AppwriteException catch (e) {
      debugPrint('[AppwriteAuth] signUp failed: ${e.message}');
      return (ok: false, message: e.message ?? e.toString());
    } catch (e) {
      return (ok: false, message: e.toString());
    }
  }

  // ── Sign In ──
  static Future<({bool ok, String message})> signIn({
    required String email,
    required String password,
  }) async {
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');
    try {
      await AppwriteService.account.createEmailPasswordSession(email: email.trim(), password: password);
      final me = await AppwriteService.account.get();
      appwriteUserNotifier.value = me;
      return (ok: true, message: 'Welcome back!');
    } on AppwriteException catch (e) {
      return (ok: false, message: e.message ?? e.toString());
    } catch (e) {
      return (ok: false, message: e.toString());
    }
  }

  /// Demo admin — tries real Appwrite login, creates user if missing, then queries DB.
  /// Falls back to local only when Appwrite is unreachable/offline.
  static Future<({bool ok, String message})> signInAsDummyAdmin() async {
    final email = appwriteAdminEmails.first;
    if (AppwriteService.isInitialized) {
      try {
        await AppwriteService.account.createEmailPasswordSession(email: email, password: appwriteAdminPassword);
        final me = await AppwriteService.account.get();
        _demoUser = null;
        appwriteUserNotifier.value = me;
        debugPrint('[AppwriteAuth] Demo admin signed in (existing): $email');
        return (ok: true, message: 'Welcome back!');
      } catch (e) {
        debugPrint('[AppwriteAuth] signIn failed: $e — trying create');
        // User may not exist — try create then login
        try {
          await AppwriteService.account.create(
            userId: ID.unique(),
            email: email,
            password: appwriteAdminPassword,
            name: 'Admin',
          );
          await AppwriteService.account.createEmailPasswordSession(email: email, password: appwriteAdminPassword);
          final me = await AppwriteService.account.get();
          _demoUser = null;
          appwriteUserNotifier.value = me;
          debugPrint('[AppwriteAuth] Demo admin created & signed in: $email');
          return (ok: true, message: 'Admin created & signed in');
        } catch (e2) {
          debugPrint('[AppwriteAuth] create also failed: $e2 — falling to local demo');
          // fall through to local bypass only if Appwrite unreachable
          final msg = e2.toString().toLowerCase();
          if (msg.contains('network') || msg.contains('socket') || msg.contains('timeout') || msg.contains('failed host')) {
            // offline — allow local demo
          } else if (!msg.contains('already exists') && !msg.contains('409')) {
            // For auth errors (401) we don't fallback — surface error to user
            return (ok: false, message: e2 is AppwriteException ? (e2.message ?? e2.toString()) : e2.toString());
          }
          if (msg.contains('already exists') || msg.contains('409')) {
            // race: try login once more
            try {
              await AppwriteService.account.createEmailPasswordSession(email: email, password: appwriteAdminPassword);
              final me = await AppwriteService.account.get();
              _demoUser = null;
              appwriteUserNotifier.value = me;
              return (ok: true, message: 'Welcome back!');
            } catch (_) {}
          }
        }
      }
      // Only fallback to local if truly offline (Appwrite unreachable)
      // Check if we still haven't succeeded and error is network-related
      // For now, if we reach here and Appwrite is configured but auth failed due to permissions (401), don't fallback silently — inform user
      // However to keep previous behavior for offline dev, allow fallback when network failure
      try {
        final test = await AppwriteService.account.get().timeout(const Duration(seconds: 3));
        // if get succeeded, we shouldn't be here
        appwriteUserNotifier.value = test;
        return (ok: true, message: 'Welcome back!');
      } catch (_) {}
    }
    // Local fake user
    _demoUser = models.User(
      $id: 'demo-admin-001',
      $createdAt: DateTime.now().toIso8601String(),
      $updatedAt: DateTime.now().toIso8601String(),
      name: 'Admin',
      password: '',
      hash: '',
      hashOptions: null,
      registration: DateTime.now().toIso8601String(),
      status: true,
      labels: [],
      passwordUpdate: DateTime.now().toIso8601String(),
      email: email,
      phone: '',
      emailVerification: true,
      phoneVerification: false,
      mfa: false,
      prefs: models.Preferences(data: {}),
      targets: [],
      accessedAt: DateTime.now().toIso8601String(),
    );
    appwriteUserNotifier.value = _demoUser;
    debugPrint('[AppwriteAuth] Demo admin signed in locally: $email');
    return (ok: true, message: 'Logged in as admin (demo mode)');
  }

  /// Demo customer — tries real Appwrite login, creates user if missing.
  /// Falls back to local only when Appwrite is unreachable/offline.
  static Future<({bool ok, String message})> signInAsDummyCustomer() async {
    final email = appwriteDummyCustomerEmail;
    if (AppwriteService.isInitialized) {
      try {
        await AppwriteService.account.createEmailPasswordSession(email: email, password: appwriteDummyCustomerPassword);
        final me = await AppwriteService.account.get();
        _demoUser = null;
        appwriteUserNotifier.value = me;
        debugPrint('[AppwriteAuth] Demo customer signed in (existing): $email');
        return (ok: true, message: 'Welcome back!');
      } catch (e) {
        debugPrint('[AppwriteAuth] signIn failed: $e — trying create');
        try {
          await AppwriteService.account.create(
            userId: ID.unique(),
            email: email,
            password: appwriteDummyCustomerPassword,
            name: 'Customer',
          );
          await AppwriteService.account.createEmailPasswordSession(email: email, password: appwriteDummyCustomerPassword);
          final me = await AppwriteService.account.get();
          _demoUser = null;
          appwriteUserNotifier.value = me;
          debugPrint('[AppwriteAuth] Demo customer created & signed in: $email');
          return (ok: true, message: 'Customer created & signed in');
        } catch (e2) {
          debugPrint('[AppwriteAuth] create also failed: $e2 — falling to local demo');
          final msg = e2.toString().toLowerCase();
          if (msg.contains('network') || msg.contains('socket') || msg.contains('timeout') || msg.contains('failed host')) {
            // offline — allow local demo
          } else if (!msg.contains('already exists') && !msg.contains('409')) {
            return (ok: false, message: e2 is AppwriteException ? (e2.message ?? e2.toString()) : e2.toString());
          }
          if (msg.contains('already exists') || msg.contains('409')) {
            try {
              await AppwriteService.account.createEmailPasswordSession(email: email, password: appwriteDummyCustomerPassword);
              final me = await AppwriteService.account.get();
              _demoUser = null;
              appwriteUserNotifier.value = me;
              return (ok: true, message: 'Welcome back!');
            } catch (_) {}
          }
        }
      }
      try {
        final test = await AppwriteService.account.get().timeout(const Duration(seconds: 3));
        appwriteUserNotifier.value = test;
        return (ok: true, message: 'Welcome back!');
      } catch (_) {}
    }
    // Local fake user
    _demoUser = models.User(
      $id: 'demo-customer-001',
      $createdAt: DateTime.now().toIso8601String(),
      $updatedAt: DateTime.now().toIso8601String(),
      name: 'Customer',
      password: '',
      hash: '',
      hashOptions: null,
      registration: DateTime.now().toIso8601String(),
      status: true,
      labels: [],
      passwordUpdate: DateTime.now().toIso8601String(),
      email: email,
      phone: '',
      emailVerification: true,
      phoneVerification: false,
      mfa: false,
      prefs: models.Preferences(data: {}),
      targets: [],
      accessedAt: DateTime.now().toIso8601String(),
    );
    appwriteUserNotifier.value = _demoUser;
    debugPrint('[AppwriteAuth] Demo customer signed in locally: $email');
    return (ok: true, message: 'Logged in as customer (demo mode)');
  }

  // ── Password Reset ──
  static Future<({bool ok, String message})> sendPasswordReset(String email) async {
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');
    try {
      // Appwrite requires a URL for recovery redirect; use endpoint as placeholder — configure in console.
      await AppwriteService.account.createRecovery(email: email.trim(), url: 'https://hariomtraders.com/reset');
      return (ok: true, message: 'Reset link sent to $email');
    } on AppwriteException catch (e) {
      return (ok: false, message: e.message ?? e.toString());
    } catch (e) {
      return (ok: false, message: e.toString());
    }
  }

  // ── Sign Out ──
  static Future<void> signOut() async {
    if (_demoUser != null) {
      _demoUser = null;
      appwriteUserNotifier.value = null;
      debugPrint('[AppwriteAuth] Demo admin signed out');
      return;
    }
    if (!AppwriteService.isInitialized) return;
    try {
      await AppwriteService.account.deleteSession(sessionId: 'current');
      appwriteUserNotifier.value = null;
    } catch (e) {
      debugPrint('[AppwriteAuth] signOut failed: $e');
    }
  }

  /// For compatibility with Supabase dummyAdmin tuple
  static ({String email, String password}) get dummyAdmin => (email: appwriteAdminEmails.first, password: appwriteAdminPassword);

  /// For compatibility — dummy customer tuple
  static ({String email, String password}) get dummyCustomer => (email: appwriteDummyCustomerEmail, password: appwriteDummyCustomerPassword);
}
