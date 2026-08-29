import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'appwrite_client.dart';
import 'appwrite_config.dart';
import '../core/errors/auth_error.dart';
import '../core/validators/auth_validators.dart';
import '../models/user_model.dart';
import '../services/email_auth_service.dart';
import '../services/email_service.dart';

/// Global notifiers for auth state — consumed by GoRouter refreshListenable.
final ValueNotifier<models.User?> appwriteUserNotifier = ValueNotifier<models.User?>(null);
final ValueNotifier<models.Session?> appwriteSessionNotifier = ValueNotifier<models.Session?>(null);

// ── Demo credentials ──
const List<String> appwriteAdminEmails = [
  'admin@hariomtraders.com',
  'mahadevft6@gmail.com',
  'demo@hariomtraders.com',
];
const String appwriteAdminPassword = 'HariOm@2026';
const String appwriteDummyCustomerEmail = 'customer@hariomtraders.com';
const String appwriteDummyCustomerPassword = 'HariOm@2026';

/// Production-ready Appwrite auth service.
///
/// Source of truth: Appwrite Auth (email/password/sessions).
/// Application profile lives in `hari_om_db.users` and is linked via `userId == $id`.
/// Never stores passwords or OTPs persistently beyond in-memory verified flag.
class AppwriteAuthService {
  AppwriteAuthService._();
  static models.User? _demoUser;
  static UserModel? _cachedProfile;
  static bool get isDemoAdmin => _demoUser != null;

  // ── Helpers ──
  static String _friendly(Object e) => AuthError.friendly(e);

  static bool _isNetworkError(Object e) => AuthError.isNetwork(e);

  // ── Session / Auth state ──

  /// Call in `main()` to restore existing session and profile.
  static Future<void> initListener() async {
    if (!AppwriteService.isInitialized) return;
    try {
      final user = await AppwriteService.account.get();
      appwriteUserNotifier.value = user;
      // Fire-and-forget profile load (does not block routing)
      unawaited(getProfile().then((p) {
        _cachedProfile = p;
        _notifyRouter();
      }));
      debugPrint('[Auth] restored session: ${user.email}');
    } catch (_) {
      appwriteUserNotifier.value = _demoUser;
      _cachedProfile = null;
      debugPrint('[Auth] no active session');
    }
  }

  /// Explicit session restoration — used on app startup.
  /// Returns true if session valid.
  static Future<bool> restoreSession() async {
    if (_demoUser != null) return true;
    if (!AppwriteService.isInitialized) return false;
    try {
      final user = await AppwriteService.account.get();
      appwriteUserNotifier.value = user;
      _cachedProfile = await getProfile();
      _notifyRouter();
      return true;
    } catch (_) {
      appwriteUserNotifier.value = null;
      _cachedProfile = null;
      return false;
    }
  }

  static models.User? get currentUser => _demoUser ?? appwriteUserNotifier.value;
  static UserModel? get currentProfile => _cachedProfile;
  static bool get isLoggedIn => currentUser != null;
  static bool get isAuthenticated => isLoggedIn; // alias for prompt spec
  static bool get isAdmin {
    final u = currentUser;
    if (u == null) return false;
    if (_demoUser != null) return true;
    // Prefer profile role if available
    if (_cachedProfile != null) return _cachedProfile!.isAdmin;
    return appwriteAdminEmails.contains(u.email.toLowerCase().trim());
  }

  static Future<bool> canRestoreSession() => restoreSession();

  /// Re-fetch the cached profile from the DB (e.g. after an admin edits the
  /// currently logged-in user's role/status) and notify the router so the
  /// dashboard redirect re-evaluates.
  static Future<void> refreshProfile() async {
    final u = currentUser;
    if (u == null || _demoUser != null) return;
    if (!AppwriteService.isInitialized) return;
    try {
      _cachedProfile = await getProfile();
      _notifyRouter();
      debugPrint('[Auth] refreshed cached profile: role=${_cachedProfile?.role}');
    } catch (e) {
      debugPrint('[Auth] refreshProfile failed: $e');
    }
  }

  /// Fires the router's refreshListenable so GoRouter redirects re-evaluate on
  /// profile/role changes (not just session changes).
  static void _notifyRouter() {
    appwriteUserNotifier.value = appwriteUserNotifier.value;
  }

  static String get displayName {
    if (_cachedProfile != null && _cachedProfile!.name.trim().isNotEmpty) return _cachedProfile!.name;
    final u = currentUser;
    if (u == null) return '';
    final n = u.name.trim();
    return n.isNotEmpty ? n : u.email.split('@').first;
  }

  static String get displayEmail => _cachedProfile?.email ?? currentUser?.email ?? '';
  static ({String email, String password}) get dummyAdmin => (email: appwriteAdminEmails.first, password: appwriteAdminPassword);
  static ({String email, String password}) get dummyCustomer => (email: appwriteDummyCustomerEmail, password: appwriteDummyCustomerPassword);

  // ── Profile helpers ──

  /// Fetch application profile for the current logged-in user.
  /// Returns null if not found or not logged in.
  static Future<UserModel?> getProfile() async {
    final u = currentUser;
    if (u == null || _demoUser != null) return null;
    if (!AppwriteService.isInitialized) return null;
    try {
      // Try by documentId == userId first, then by email index
      try {
        final doc = await AppwriteService.databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollectionId,
          documentId: u.$id,
        );
        return UserModel.fromDocument(doc);
      } catch (_) {
        final res = await AppwriteService.databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollectionId,
          queries: [Query.equal('userId', u.$id), Query.limit(1)],
        );
        if (res.documents.isNotEmpty) return UserModel.fromDocument(res.documents.first);
        // fallback by email (legacy where docId != userId)
        final byEmail = await AppwriteService.databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollectionId,
          queries: [Query.equal('email', u.email.toLowerCase().trim()), Query.limit(1)],
        );
        if (byEmail.documents.isNotEmpty) return UserModel.fromDocument(byEmail.documents.first);
      }
    } catch (e) {
      debugPrint('[Auth] getProfile failed: $e');
    }
    return null;
  }

  static Future<UserModel?> getProfileByEmail(String email) async {
    if (!AppwriteService.isInitialized) return null;
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [Query.equal('email', email.toLowerCase().trim()), Query.limit(1)],
      );
      if (res.documents.isNotEmpty) return UserModel.fromDocument(res.documents.first);
    } catch (e) {
      debugPrint('[Auth] getProfileByEmail failed: $e');
    }
    return null;
  }

  // ── DB backfill ──
  static Future<void> _ensureUserDoc(models.User user) async {
    if (!AppwriteService.isInitialized) return;
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [Query.equal('email', user.email.toLowerCase().trim()), Query.limit(1)],
      );
      if (res.documents.isNotEmpty) {
        // Refresh cache
        _cachedProfile = UserModel.fromDocument(res.documents.first);
        _notifyRouter();
        return;
      }
      final doc = await AppwriteService.databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: user.$id,
        data: {
          'userId': user.$id,
          'name': user.name.trim().isEmpty ? user.email.split('@').first : user.name.trim(),
          'email': user.email.trim().toLowerCase(),
          'phone': user.phone.trim(),
          'role': 'customer',
          'privileges': '["view_products","place_orders","view_orders","manage_cart","manage_wishlist","view_invoices","manage_profile","contact_support"]',
          'status': 'active',
          'emailVerification': user.emailVerification,
          'phoneVerification': user.phoneVerification,
        },
      );
      _cachedProfile = UserModel.fromDocument(doc);
      _notifyRouter();
      debugPrint('[Auth] backfilled users doc for ${user.email}');
    } catch (e) {
      debugPrint('[Auth] _ensureUserDoc: $e');
    }
  }

  // ── Sign Up ──
  static Future<({bool ok, String message})> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');
    final n = name.trim(), e = email.trim(), p = password;
    final nameErr = AuthValidators.validateName(n);
    if (nameErr != null) return (ok: false, message: nameErr);
    final emailErr = AuthValidators.validateEmail(e);
    if (emailErr != null) return (ok: false, message: emailErr);
    final passErr = AuthValidators.validatePassword(p);
    if (passErr != null) return (ok: false, message: passErr);
    try {
      final user = await AppwriteService.account.create(userId: ID.unique(), email: e, password: p, name: n);
      try {
        await AppwriteService.databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollectionId,
          documentId: user.$id,
          data: {
            'userId': user.$id,
            'name': n,
            'email': e.toLowerCase(),
            'phone': '',
            'role': 'customer',
            'privileges': '["view_products","place_orders","view_orders","manage_cart","manage_wishlist","view_invoices","manage_profile","contact_support"]',
            'status': 'active',
            'emailVerification': false,
            'phoneVerification': false,
          },
        );
      } catch (dbErr) {
        debugPrint('[Auth] DB doc create failed (non-fatal): $dbErr');
      }
      await AppwriteService.account.createEmailPasswordSession(email: e, password: p);
      final me = await AppwriteService.account.get();
      appwriteUserNotifier.value = me;
      await _ensureUserDoc(me);
      debugPrint('[Auth] signUp ok: $e');
      return (ok: true, message: 'Account created!');
} on AppwriteException catch (e) {
      return (ok: false, message: _friendly(e));
    } catch (e) {
      return (ok: false, message: _friendly(e));
    }
  }

  // ── Sign Up with Email OTP Verification ──
  // Two-phase signup: (1) [sendSignupOtp] emails an OTP to prove email
  // ownership — NO account is created yet; (2) [verifySignupOtp] creates the
  // Appwrite account, its user document and a session only after verification.
  static final Map<String, ({String name, String password, DateTime expiresAt})> _pendingSignups = {};

  /// True when a matching user already exists (checked via the Management API).
  /// Fails open (returns false) so signup is never blocked by a lookup error —
  /// Appwrite's account.create still enforces uniqueness as a final guard.
  static Future<bool> _emailAlreadyRegistered(String email) async {
    final e = email.trim().toLowerCase();
    final key = AppwriteConfig.appwriteApiKey.trim();
    if (key.isEmpty) {
      debugPrint('[Auth] API key not configured — skipping duplicate-email check');
      return false;
    }
    try {
      final listUri = Uri.parse(
        '${AppwriteConfig.endpoint}/users?queries[]=${Uri.encodeComponent('{"method":"equal","attribute":"email","values":["$e"]}')}',
      );
      final res = await http.get(listUri, headers: {
        'X-Appwrite-Project': AppwriteConfig.projectId,
        'X-Appwrite-Key': key,
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        debugPrint('[Auth] duplicate-email check failed ${res.statusCode}: ${res.body}');
        return false;
      }
      final total = (jsonDecode(res.body) as Map<String, dynamic>)['total'] as int? ?? 0;
      return total > 0;
    } catch (e) {
      debugPrint('[Auth] duplicate-email check error: $e');
      return false;
    }
  }

  /// Step 1 (signup): send an OTP to verify email ownership.
  /// [debugOtp] is set in debug mode when email cannot actually be sent.
  static Future<({bool ok, String message, String? debugOtp, String? otpId})> sendSignupOtp({
    required String name,
    required String email,
    required String password,
  }) async {
    final n = name.trim();
    final e = email.trim().toLowerCase();
    final p = password;
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured', debugOtp: null, otpId: null);
    final nameErr = AuthValidators.validateName(n);
    if (nameErr != null) return (ok: false, message: nameErr, debugOtp: null, otpId: null);
    final emailErr = AuthValidators.validateEmail(e);
    if (emailErr != null) return (ok: false, message: emailErr, debugOtp: null, otpId: null);
    final passErr = AuthValidators.validatePassword(p);
    if (passErr != null) return (ok: false, message: passErr, debugOtp: null, otpId: null);
    if (!canResendOtp(e)) {
      final r = resendCooldownRemaining(e);
      return (ok: false, message: 'Please wait ${r}s before resending', debugOtp: null, otpId: null);
    }
    // Never send an OTP for an email that already has an account.
    if (await _emailAlreadyRegistered(e)) {
      return (ok: false, message: 'An account already exists for $e. Try logging in.', debugOtp: null, otpId: null);
    }

    final otp = _generateOtp();
    final otpId = _generateOtpId();
    _otpStore[e] = (otp: otp, otpId: otpId, expiresAt: DateTime.now().toUtc().add(otpExpiry));
    _pendingSignups[e] = (name: n, password: p, expiresAt: DateTime.now().toUtc().add(otpExpiry));
    _verifiedEmails.remove(e);
    _lastOtpSentAt[e] = DateTime.now();
    _emailAuthSent.remove(e);

    final sent = await EmailService.instance.sendOtpEmail(email: e, otp: otp, otpId: otpId, purpose: OtpEmailPurpose.signup);
    if (!sent) {
      if (kDebugMode) {
        debugPrint('[Auth] ⚠️ Signup email send failed — returning OTP for debug display (keeping in-memory OTP alive)');
        // Keep _otpStore/_pendingSignups so Verify still works in debug/web.
        return (ok: true, message: 'Email send failed (debug: OTP available below)', debugOtp: otp, otpId: otpId);
      }
      _otpStore.remove(e);
      _pendingSignups.remove(e);
      return (ok: false, message: 'Failed to send OTP. Please try again.', debugOtp: null, otpId: null);
    }
    debugPrint('[Auth] Signup OTP sent to $e (ID: $otpId)');
    return (ok: true, message: 'Verification code sent to $e', debugOtp: null, otpId: otpId);
  }

  /// Resend a signup OTP for an email that already has one pending.
  static Future<({bool ok, String message, String? debugOtp, String? otpId})> resendSignupOtp(String email) async {
    final e = email.trim().toLowerCase();
    final pending = _pendingSignups[e];
    if (pending == null) {
      return (ok: false, message: 'No pending signup. Please re-enter your details.', debugOtp: null, otpId: null);
    }
    return sendSignupOtp(name: pending.name, email: e, password: pending.password);
  }

  /// Discard a pending signup (used when the user backs out of the OTP step).
  static void cancelSignupOtp(String email) {
    final e = email.trim().toLowerCase();
    _otpStore.remove(e);
    _pendingSignups.remove(e);
    _verifiedEmails.remove(e);
  }

  /// Step 2 (signup): verify the OTP, then — only on success — create the
  /// Appwrite account, its user document, a session, and log the user in.
  static Future<({bool ok, String message})> verifySignupOtp(String email, String otp) async {
    final e = email.trim().toLowerCase();
    // Sanitize: user may paste "4 1 7 8 3 3" or "417-833" — keep only digits.
    final cleanOtp = otp.replaceAll(RegExp(r'\D'), '').trim();
    final otpErr = AuthValidators.validateOtp(cleanOtp);
    if (otpErr != null) return (ok: false, message: otpErr);

    final entry = _otpStore[e];
    if (entry == null) return (ok: false, message: 'No OTP found. Please request a new one.');
    if (DateTime.now().toUtc().isAfter(entry.expiresAt)) {
      _otpStore.remove(e);
      _pendingSignups.remove(e);
      return (ok: false, message: 'This OTP has expired. Please request a new one.');
    }
    if (entry.otp != cleanOtp) return (ok: false, message: 'The OTP is incorrect. Please try again.');
    final pending = _pendingSignups[e];
    if (pending == null) return (ok: false, message: 'No pending signup found. Please start over.');

    // OTP verified — email ownership proven.
    _otpStore.remove(e);
    _verifiedEmails.add(e);
    _pendingSignups.remove(e);
    Future.delayed(const Duration(minutes: 10), () => _verifiedEmails.remove(e));

    // Final guard against duplicate accounts created while the OTP was valid.
    if (await _emailAlreadyRegistered(e)) {
      return (ok: false, message: 'An account already exists for $e. Try logging in.');
    }

    try {
      debugPrint('[Auth] verifySignupOtp: OTP correct for $e, creating account…');
      final user = await AppwriteService.account.create(userId: ID.unique(), email: e, password: pending.password, name: pending.name);
      try {
        await AppwriteService.databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollectionId,
          documentId: user.$id,
          data: {
            'userId': user.$id,
            'name': pending.name,
            'email': e,
            'phone': '',
            'role': 'customer',
            'privileges': '["view_products","place_orders","view_orders","manage_cart","manage_wishlist","view_invoices","manage_profile","contact_support"]',
            'status': 'active',
            'emailVerification': true,
            'phoneVerification': false,
          },
        );
      } catch (dbErr) {
        debugPrint('[Auth] DB doc create failed (non-fatal): $dbErr');
      }
      await AppwriteService.account.createEmailPasswordSession(email: e, password: pending.password);
      final me = await AppwriteService.account.get();
      _demoUser = null;
      await _ensureUserDoc(me);
      appwriteUserNotifier.value = me;
      debugPrint('[Auth] signup (verified OTP) ok: $e');
      return (ok: true, message: 'Account created — welcome!');
    } on AppwriteException catch (e2) {
      debugPrint('[Auth] verifySignupOtp create failed: ${e2.code} ${e2.message}');
      final msg = _friendly(e2);
      // If friendly falls back to generic, include code for debugging.
      if (msg == 'Something went wrong. Please try again.' && e2.message != null && e2.message!.trim().isNotEmpty) {
        return (ok: false, message: e2.message!.trim());
      }
      return (ok: false, message: msg);
    } catch (e2) {
      debugPrint('[Auth] verifySignupOtp unexpected: $e2');
      final msg = _friendly(e2);
      if (msg == 'Something went wrong. Please try again.') return (ok: false, message: 'Signup failed: $e2');
      return (ok: false, message: msg);
    }
  }

  // ── Sign In ──
  static Future<({bool ok, String message})> signIn({
    required String email,
    required String password,
  }) async {
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');
    final e = email.trim(), p = password;
    final emailErr = AuthValidators.validateEmail(e);
    if (emailErr != null) return (ok: false, message: emailErr);
    if (p.isEmpty) return (ok: false, message: 'Enter your password');
    try {
      await AppwriteService.account.createEmailPasswordSession(email: e, password: p);
      final me = await AppwriteService.account.get();
      _demoUser = null;
      await _ensureUserDoc(me);
      appwriteUserNotifier.value = me;
      debugPrint('[Auth] signIn ok: $e');
      return (ok: true, message: 'Welcome back!');
    } on AppwriteException catch (e) {
      return (ok: false, message: _friendly(e));
    } catch (e) {
      return (ok: false, message: _friendly(e));
    }
  }

  // ── Demo helpers ──
  static Future<({bool ok, String message})> _signInOrCreateDemo(String email, String password, String name) async {
    if (!AppwriteService.isInitialized) {
      _demoUser = _fakeUser(email: email, name: name);
      appwriteUserNotifier.value = _demoUser;
      return (ok: true, message: 'Logged in as $name (demo mode)');
    }
    try {
      await AppwriteService.account.createEmailPasswordSession(email: email, password: password);
      final me = await AppwriteService.account.get();
      _demoUser = null;
      await _ensureUserDoc(me);
      appwriteUserNotifier.value = me;
      return (ok: true, message: 'Welcome back!');
    } on AppwriteException catch (e) {
      final code = e.code ?? 0;
      if (code == 401 || (e.message ?? '').toLowerCase().contains('invalid credentials')) {
        try {
          await AppwriteService.account.create(userId: ID.unique(), email: email, password: password, name: name);
          await AppwriteService.account.createEmailPasswordSession(email: email, password: password);
          final me = await AppwriteService.account.get();
          _demoUser = null;
          await _ensureUserDoc(me);
          appwriteUserNotifier.value = me;
          return (ok: true, message: '$name created & signed in');
        } on AppwriteException catch (e2) {
          if (e2.code == 409 || (e2.message ?? '').toLowerCase().contains('already exists')) {
            try {
              await AppwriteService.account.createEmailPasswordSession(email: email, password: password);
              final me = await AppwriteService.account.get();
              _demoUser = null;
              await _ensureUserDoc(me);
              appwriteUserNotifier.value = me;
              return (ok: true, message: 'Welcome back!');
            } catch (_) {}
          }
          if (_isNetworkError(e2)) {
            _demoUser = _fakeUser(email: email, name: name);
            appwriteUserNotifier.value = _demoUser;
            return (ok: true, message: 'Logged in as $name (demo mode)');
          }
          return (ok: false, message: _friendly(e2));
        }
      }
      if (_isNetworkError(e)) {
        _demoUser = _fakeUser(email: email, name: name);
        appwriteUserNotifier.value = _demoUser;
        return (ok: true, message: 'Logged in as $name (demo mode)');
      }
      return (ok: false, message: _friendly(e));
    }
  }

  static Future<({bool ok, String message})> signInAsDummyAdmin() =>
      _signInOrCreateDemo(appwriteAdminEmails.first, appwriteAdminPassword, 'Admin');
  static Future<({bool ok, String message})> signInAsDummyCustomer() =>
      _signInOrCreateDemo(appwriteDummyCustomerEmail, appwriteDummyCustomerPassword, 'Customer');

  static models.User _fakeUser({required String email, required String name}) {
    final now = DateTime.now().toIso8601String();
    return models.User(
      $id: 'demo-${email.hashCode}',
      $createdAt: now,
      $updatedAt: now,
      name: name,
      password: '',
      hash: '',
      hashOptions: null,
      registration: now,
      status: true,
      labels: [],
      passwordUpdate: now,
      email: email,
      phone: '',
      emailVerification: true,
      phoneVerification: false,
      mfa: false,
      prefs: models.Preferences(data: {}),
      targets: [],
      accessedAt: now,
    );
  }

  // ── OTP-based Reset Password (email_auth package) ──
  // Primary: `email_auth` package (sendOtp/validateOtp) via EmailAuthService.
  // Fallback: in-memory OTP + MailApi/Gmail for dev / when email_auth server fails.
  static final Map<String, ({String otp, String otpId, DateTime expiresAt})> _otpStore = {};
  static final Set<String> _verifiedEmails = {};
  static final Map<String, DateTime> _lastOtpSentAt = {};
  // Tracks which emails last used email_auth vs fallback store
  static final Set<String> _emailAuthSent = {};

  static const Duration otpExpiry = Duration(minutes: 10);
  static const Duration otpResendCooldown = Duration(seconds: 60);

  static String _generateOtp() => List.generate(6, (_) => Random.secure().nextInt(10)).join();
  static String _generateOtpId() => List.generate(3, (_) => Random.secure().nextInt(10)).join();

  static bool canResendOtp(String email) {
    final n = email.trim().toLowerCase();
    final last = _lastOtpSentAt[n];
    if (last == null) return true;
    return DateTime.now().difference(last) >= otpResendCooldown;
  }

  static int resendCooldownRemaining(String email) {
    final n = email.trim().toLowerCase();
    final last = _lastOtpSentAt[n];
    if (last == null) return 0;
    final elapsed = DateTime.now().difference(last);
    final remaining = otpResendCooldown.inSeconds - elapsed.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Step 1: Send OTP — prioritizes Gmail SMTP (rohitft20@gmail.com + App Password)
  /// when configured, otherwise tries email_auth package, fallback to custom Mail API.
  /// No existence gate — OTP always sent if email valid.
  /// [debugOtp] is set in debug mode when email cannot actually be sent (web/no provider).
  static Future<({bool ok, String message, String? debugOtp, String? otpId})> sendResetOtp(String email) async {
    final normalized = email.trim().toLowerCase();
    final emailErr = AuthValidators.validateEmail(normalized);
    if (emailErr != null) return (ok: false, message: emailErr, debugOtp: null, otpId: null);
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured', debugOtp: null, otpId: null);
    if (!canResendOtp(normalized)) {
      final r = resendCooldownRemaining(normalized);
      return (ok: false, message: 'Please wait ${r}s before resending', debugOtp: null, otpId: null);
    }

    // 1) Try email_auth ONLY when a custom server is configured.
    // Skip on web when Gmail SMTP isn't available — the default email_auth server is defunct.
    // On desktop/mobile with Gmail SMTP configured, skip email_auth and go direct.
    if (AppwriteConfig.isEmailAuthConfigured && !AppwriteConfig.isGmailSmtpConfigured) {
      try {
        final sentViaEmailAuth = await EmailAuthService.instance.sendOtp(email: normalized, otpLength: 6);
          if (sentViaEmailAuth) {
          _verifiedEmails.remove(normalized);
          _lastOtpSentAt[normalized] = DateTime.now();
          _emailAuthSent.add(normalized);
          _otpStore.remove(normalized);
          if (kDebugMode) debugPrint('[Auth] OTP via email_auth sent to $normalized');
          return (ok: true, message: 'OTP sent to $normalized', debugOtp: null, otpId: null);
        }
        debugPrint('[Auth] email_auth send failed, falling back to Gmail SMTP/custom OTP');
      } catch (e) {
        debugPrint('[Auth] email_auth exception: $e — fallback to Gmail SMTP/custom OTP');
      }
    } else {
      if (kDebugMode) debugPrint('[Auth] Gmail SMTP configured (${AppwriteConfig.effectiveGmailSmtpEmail}) — using Gmail App Password for OTP');
    }

    // 2) Gmail SMTP via App Password + Mail API fallback (works with rohitft20@gmail.com)
    final otp = _generateOtp();
    final otpId = _generateOtpId();
    _otpStore[normalized] = (otp: otp, otpId: otpId, expiresAt: DateTime.now().toUtc().add(otpExpiry));
    _verifiedEmails.remove(normalized);
    _lastOtpSentAt[normalized] = DateTime.now();
    _emailAuthSent.remove(normalized);
    final sent = await EmailService.instance.sendOtpEmail(email: normalized, otp: otp, otpId: otpId, purpose: OtpEmailPurpose.passwordReset);
    if (!sent) {
      // Email failed to send. In debug mode, return the OTP so UI can display it.
      if (kDebugMode) {
        debugPrint('[Auth] ⚠️ Email send failed — returning OTP for debug display');
        return (ok: true, message: 'Email send failed (debug: OTP available below)', debugOtp: otp, otpId: otpId);
      }
      _otpStore.remove(normalized);
      return (ok: false, message: 'Failed to send OTP. Please try again.', debugOtp: null, otpId: null);
    }
    if (kDebugMode) debugPrint('[Auth] OTP sent to $normalized (ID: $otpId)');
    return (ok: true, message: 'OTP sent to $normalized', debugOtp: null, otpId: otpId);
  }

  /// Step 2: Verify OTP via `email_auth` validateOtp, fallback to in-memory store.
  static Future<({bool ok, String message})> verifyResetOtp(String email, String otp) async {
    final normalized = email.trim().toLowerCase();
    final cleanOtp = otp.replaceAll(RegExp(r'\D'), '').trim();
    final otpErr = AuthValidators.validateOtp(cleanOtp);
    if (otpErr != null) return (ok: false, message: otpErr);

    // 1) Try email_auth validation if last send was via email_auth
    if (_emailAuthSent.contains(normalized)) {
      final ok = EmailAuthService.instance.verifyOtp(email: normalized, otp: cleanOtp);
      if (ok) {
        _verifiedEmails.add(normalized);
        _emailAuthSent.remove(normalized);
        Future.delayed(const Duration(minutes: 10), () => _verifiedEmails.remove(normalized));
        return (ok: true, message: 'OTP verified');
      }
      // If email_auth rejects, still allow fallback check (in case user had older fallback OTP)
      // but prefer to return precise error for email_auth path
      final fallbackEntry = _otpStore[normalized];
      if (fallbackEntry == null) {
        return (ok: false, message: 'The OTP is incorrect. Please try again.');
      }
    }

    // 2) Fallback: in-memory store
    final entry = _otpStore[normalized];
    if (entry == null) return (ok: false, message: 'No OTP found. Please request a new one.');
    if (DateTime.now().toUtc().isAfter(entry.expiresAt)) {
      _otpStore.remove(normalized);
      return (ok: false, message: 'This OTP has expired. Please request a new one.');
    }
    if (entry.otp != cleanOtp) return (ok: false, message: 'The OTP is incorrect. Please try again.');
    _otpStore.remove(normalized);
    _verifiedEmails.add(normalized);
    Future.delayed(const Duration(minutes: 10), () => _verifiedEmails.remove(normalized));
    return (ok: true, message: 'OTP verified');
  }

  /// Step 3a: Legacy recovery-token path (used when navigating to /reset page).
  static Future<({bool ok, String? userId, String? secret, String? expire, String? error})> initiateRecovery(String email) async {
    if (!AppwriteService.isInitialized) return (ok: false, userId: null, secret: null, expire: null, error: 'Appwrite not configured');
    final normalized = email.trim().toLowerCase();
    if (!_verifiedEmails.contains(normalized)) {
      return (ok: false, userId: null, secret: null, expire: null, error: 'Please verify OTP first');
    }
    try {
      final url = kIsWeb ? '${Uri.base.origin}/reset' : 'https://hariomtraders.com/reset';
      final token = await AppwriteService.account.createRecovery(email: normalized, url: url);
      return (ok: true, userId: token.userId, secret: token.secret, expire: token.expire.toString(), error: null);
    } on AppwriteException catch (e) {
      return (ok: false, userId: null, secret: null, expire: null, error: _friendly(e));
    } catch (e) {
      return (ok: false, userId: null, secret: null, expire: null, error: _friendly(e));
    }
  }

  /// Step 3b: Direct reset using OTP-verified email (primary path from AuthPage).
  /// Uses Appwrite Management API (users.lookup + users.updatePassword) directly —
  /// requires APPWRITE_API_KEY with users.read + users.write scopes.
  /// Inject via --dart-define=APPWRITE_API_KEY=your_key
  /// Falls back to relay server if API key not configured.
  static Future<({bool ok, String message})> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!_verifiedEmails.contains(normalized)) {
      return (ok: false, message: 'Please verify OTP first');
    }
    final passErr = AuthValidators.validatePassword(newPassword);
    if (passErr != null) return (ok: false, message: passErr);
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');

    // 1) Primary: Appwrite Management API via HTTP (no relay server needed).
    // Requires APPWRITE_API_KEY with users.read + users.write scopes.
    if (AppwriteConfig.isApiKeyConfigured) {
      try {
        final endpoint = AppwriteConfig.endpoint;
        final apiKey = AppwriteConfig.appwriteApiKey;
        final projectId = AppwriteConfig.projectId;

// Step A: Find user by email.
        // Note: Appwrite v1.x+ expects JSON-encoded queries (matching Query.toString()),
        // e.g. {"method":"equal","attribute":"email","values":["..."]} — the legacy
        // equal("email", "...") string format returns HTTP 400.
        final listUri = Uri.parse(
          '$endpoint/users?queries[]=${Uri.encodeComponent('{"method":"equal","attribute":"email","values":["$normalized"]}')}',
        );
        final listRes = await http.get(listUri, headers: {
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
        }).timeout(const Duration(seconds: 10));

        if (listRes.statusCode != 200) {
          debugPrint('[Auth] Management API list users failed ${listRes.statusCode}: ${listRes.body}');
          return (ok: false, message: 'Failed to find account. Please try again.');
        }

        final listJson = jsonDecode(listRes.body) as Map<String, dynamic>;
        final users = (listJson['users'] as List?) ?? [];
        if (users.isEmpty) {
          return (ok: false, message: 'No account found for $normalized');
        }

        final userId = (users.first as Map<String, dynamic>)['\$id'] as String;
        debugPrint('[Auth] Found userId=$userId for $normalized');

        // Step B: Update password
        final patchUri = Uri.parse('$endpoint/users/$userId/password');
        final patchRes = await http.patch(patchUri, headers: {
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
          'Content-Type': 'application/json',
        }, body: jsonEncode({'password': newPassword})).timeout(const Duration(seconds: 10));

        if (patchRes.statusCode >= 200 && patchRes.statusCode < 300) {
          debugPrint('[Auth] ✅ Password reset via Management API for $normalized');
          _verifiedEmails.remove(normalized);
          return (ok: true, message: 'Password reset successful. Please log in.');
        }

        debugPrint('[Auth] Management API update failed ${patchRes.statusCode}: ${patchRes.body}');
        return (ok: false, message: 'Failed to update password. Please try again.');
      } catch (e) {
        debugPrint('[Auth] Management API error: $e');
        return (ok: false, message: 'Password reset failed: $e');
      }
    }

    // 2) Fallback: local relay server (tools/smtp_server.dart POST /reset-password).
    // Requires APPWRITE_API_KEY env var on the relay server.
    try {
      final relayUri = Uri.parse('http://localhost:8080/reset-password');
      final r = await http
          .post(relayUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': normalized, 'newPassword': newPassword}))
          .timeout(const Duration(seconds: 15));
      final body = r.body.isNotEmpty ? jsonDecode(r.body) as Map<String, dynamic> : <String, dynamic>{};
      if (r.statusCode >= 200 && r.statusCode < 300 && (body['success'] == true)) {
        _verifiedEmails.remove(normalized);
        return (ok: true, message: (body['message'] as String?) ?? 'Password reset successful. Please log in.');
      }
      debugPrint('[Auth] relay reset failed ${r.statusCode}: ${body['error']}');
      return (ok: false, message: 'Password reset failed. Set APPWRITE_API_KEY via --dart-define or run relay server.');
    } catch (e) {
      debugPrint('[Auth] relay not reachable ($e)');
      return (ok: false, message: 'Password reset not configured. Pass --dart-define=APPWRITE_API_KEY="your_key" when building.');
    }
} 

  /// Update password after OTP verification
  /// [newPassword] must meet minimum 8-character requirement.
  /// Does NOT require the old password (OTP flow).
  /// Uses the single verified email from [_verifiedEmails].
  static Future<({bool ok, String message})> updatePasswordAfterOtp({
    required String newPassword,
  }) async {
    final normalized = AppwriteAuthService._verifiedEmails.first;
    if (normalized.isEmpty) return (ok: false, message: 'No verified email found. Verify OTP first.');

    // Only proceed if exactly one email is verified; otherwise ask user to specify
    if (AppwriteAuthService._verifiedEmails.length != 1) {
      return (ok: false, message: 'Multiple verified emails found. Please specify the account email.');
    }

    final passErr = AuthValidators.validatePassword(newPassword);
    if (passErr != null) return (ok: false, message: passErr);
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');

    try {
      debugPrint('[Auth] updatePasswordAfterOtp: resetting password for $normalized');
      final result = await resetPasswordWithOtp(email: normalized, newPassword: newPassword);
      if (result.ok) {
        return (ok: true, message: result.message);
      }
      return (ok: false, message: result.message);
    } catch (e) {
      debugPrint('[Auth] updatePasswordAfterOtp error: $e');
      return (ok: false, message: _friendly(e));
    }
  }

  static Future<({bool ok, String message})> completePasswordReset({
    required String userId,
    required String secret,
    required String newPassword,
  }) async {
    final passErr = AuthValidators.validatePassword(newPassword);
    if (passErr != null) return (ok: false, message: passErr);
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');
    try {
      await AppwriteService.account.updateRecovery(userId: userId, secret: secret, password: newPassword);
      return (ok: true, message: 'Password reset successful');
    } on AppwriteException catch (e) {
      return (ok: false, message: _friendly(e));
    } catch (e) {
      return (ok: false, message: _friendly(e));
    }
  }

  /// Update password for a logged-in user.
  ///
  /// [oldPassword] is required — Appwrite enforces it for security.
  /// [confirmPassword] is validated locally before the API call.
  static Future<({bool ok, String message})> updatePassword({
    required String oldPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    if (_demoUser != null) return (ok: false, message: 'Demo accounts cannot change password');
    if (!isLoggedIn) return (ok: false, message: 'Not logged in');
    if (oldPassword.isEmpty) return (ok: false, message: 'Current password is required');

    final passErr = AuthValidators.validatePassword(newPassword);
    if (passErr != null) return (ok: false, message: passErr);

    if (confirmPassword != null && newPassword != confirmPassword) {
      return (ok: false, message: 'Passwords do not match');
    }
    if (newPassword == oldPassword) {
      return (ok: false, message: 'New password must be different from current password');
    }
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');
    try {
      debugPrint('[Auth] updatePassword: calling Appwrite SDK');
      await AppwriteService.account.updatePassword(
        password: newPassword,
        oldPassword: oldPassword,
      );
      debugPrint('[Auth] updatePassword: success');
      return (ok: true, message: 'Password updated successfully');
    } on AppwriteException catch (e) {
      debugPrint('[Auth] updatePassword AppwriteException: ${e.code} ${e.message}');
      if (e.code == 401) return (ok: false, message: 'Current password is incorrect');
      return (ok: false, message: _friendly(e));
    } catch (e) {
      debugPrint('[Auth] updatePassword error: $e');
      return (ok: false, message: _friendly(e));
    }
  }

  // ── Sign Out ──
  static Future<void> signOut() async {
    _cachedProfile = null;
    if (_demoUser != null) {
      _demoUser = null;
      appwriteUserNotifier.value = null;
      appwriteSessionNotifier.value = null;
      return;
    }
    if (!AppwriteService.isInitialized) {
      appwriteUserNotifier.value = null;
      return;
    }
    try {
      await AppwriteService.account.deleteSession(sessionId: 'current');
      appwriteUserNotifier.value = null;
      appwriteSessionNotifier.value = null;
    } catch (e) {
      debugPrint('[Auth] signOut: $e');
      // Clear local state even if server call fails
      appwriteUserNotifier.value = null;
      appwriteSessionNotifier.value = null;
    }
  }

  /// For tests / debug: clear in-memory OTP state.
  @visibleForTesting
  static void debugClearOtpState() {
    _otpStore.clear();
    _verifiedEmails.clear();
    _lastOtpSentAt.clear();
    _emailAuthSent.clear();
  }
}
 
