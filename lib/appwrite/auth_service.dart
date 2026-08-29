import 'dart:async';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
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
      unawaited(getProfile().then((p) => _cachedProfile = p));
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
      ).catchError((err) {
        debugPrint('[Auth] DB doc create failed (non-fatal): $err');
        return null as dynamic;
      });
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
      appwriteUserNotifier.value = me;
      _demoUser = null;
      await _ensureUserDoc(me);
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
      appwriteUserNotifier.value = me;
      await _ensureUserDoc(me);
      return (ok: true, message: 'Welcome back!');
    } on AppwriteException catch (e) {
      final code = e.code ?? 0;
      if (code == 401 || (e.message ?? '').toLowerCase().contains('invalid credentials')) {
        try {
          await AppwriteService.account.create(userId: ID.unique(), email: email, password: password, name: name);
          await AppwriteService.account.createEmailPasswordSession(email: email, password: password);
          final me = await AppwriteService.account.get();
          _demoUser = null;
          appwriteUserNotifier.value = me;
          await _ensureUserDoc(me);
          return (ok: true, message: '$name created & signed in');
        } on AppwriteException catch (e2) {
          if (e2.code == 409 || (e2.message ?? '').toLowerCase().contains('already exists')) {
            try {
              await AppwriteService.account.createEmailPasswordSession(email: email, password: password);
              final me = await AppwriteService.account.get();
              _demoUser = null;
              appwriteUserNotifier.value = me;
              await _ensureUserDoc(me);
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
  static final Map<String, ({String otp, DateTime expiresAt})> _otpStore = {};
  static final Set<String> _verifiedEmails = {};
  static final Map<String, DateTime> _lastOtpSentAt = {};
  // Tracks which emails last used email_auth vs fallback store
  static final Set<String> _emailAuthSent = {};

  static const Duration otpExpiry = Duration(minutes: 10);
  static const Duration otpResendCooldown = Duration(seconds: 60);

  static String _generateOtp() => List.generate(6, (_) => Random.secure().nextInt(10)).join();

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
  static Future<({bool ok, String message, String? debugOtp})> sendResetOtp(String email) async {
    final normalized = email.trim().toLowerCase();
    final emailErr = AuthValidators.validateEmail(normalized);
    if (emailErr != null) return (ok: false, message: emailErr, debugOtp: null);
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured', debugOtp: null);
    if (!canResendOtp(normalized)) {
      final r = resendCooldownRemaining(normalized);
      return (ok: false, message: 'Please wait ${r}s before resending', debugOtp: null);
    }

    // 1) Primary when Gmail SMTP is configured — uses rohitft20@gmail.com / nrcppvuxywvttyvj
    // This is the user-requested path for reset-password OTP.
    if (!AppwriteConfig.isGmailSmtpConfigured) {
      // Only try email_auth when Gmail SMTP is NOT configured
      try {
        final sentViaEmailAuth = await EmailAuthService.instance.sendOtp(email: normalized, otpLength: 6);
        if (sentViaEmailAuth) {
          _verifiedEmails.remove(normalized);
          _lastOtpSentAt[normalized] = DateTime.now();
          _emailAuthSent.add(normalized);
          _otpStore.remove(normalized);
          if (kDebugMode) debugPrint('[Auth] OTP via email_auth sent to $normalized');
          return (ok: true, message: 'OTP sent to $normalized', debugOtp: null);
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
    _otpStore[normalized] = (otp: otp, expiresAt: DateTime.now().toUtc().add(otpExpiry));
    _verifiedEmails.remove(normalized);
    _lastOtpSentAt[normalized] = DateTime.now();
    _emailAuthSent.remove(normalized);
    final sent = await EmailService.instance.sendOtpEmail(email: normalized, otp: otp);
    if (!sent) {
      // Email failed to send. In debug mode, return the OTP so UI can display it.
      if (kDebugMode) {
        debugPrint('[Auth] ⚠️ Email send failed — returning OTP for debug display');
        return (ok: true, message: 'Email send failed (debug: OTP available below)', debugOtp: otp);
      }
      _otpStore.remove(normalized);
      return (ok: false, message: 'Failed to send OTP. Please try again.', debugOtp: null);
    }
    if (kDebugMode) debugPrint('[Auth] OTP sent to $normalized');
    return (ok: true, message: 'OTP sent to $normalized', debugOtp: null);
  }

  /// Step 2: Verify OTP via `email_auth` validateOtp, fallback to in-memory store.
  static Future<({bool ok, String message})> verifyResetOtp(String email, String otp) async {
    final normalized = email.trim().toLowerCase();
    final otpErr = AuthValidators.validateOtp(otp);
    if (otpErr != null) return (ok: false, message: otpErr);

    // 1) Try email_auth validation if last send was via email_auth
    if (_emailAuthSent.contains(normalized)) {
      final ok = EmailAuthService.instance.verifyOtp(email: normalized, otp: otp.trim());
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
    if (entry.otp != otp.trim()) return (ok: false, message: 'The OTP is incorrect. Please try again.');
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
    try {
      final url = kIsWeb ? '${Uri.base.origin}/reset' : 'https://hariomtraders.com/reset';
      final token = await AppwriteService.account.createRecovery(email: normalized, url: url);
      await AppwriteService.account.updateRecovery(userId: token.userId, secret: token.secret, password: newPassword);
      _verifiedEmails.remove(normalized);
      return (ok: true, message: 'Password reset successful. Please log in.');
    } on AppwriteException catch (e) {
      return (ok: false, message: _friendly(e));
    } catch (e) {
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

  /// Update password for logged-in user.
  static Future<({bool ok, String message})> updatePassword({
    required String newPassword,
    String? oldPassword,
  }) async {
    if (_demoUser != null) return (ok: false, message: 'Demo accounts cannot change password');
    if (!isLoggedIn) return (ok: false, message: 'Not logged in');
    final passErr = AuthValidators.validatePassword(newPassword);
    if (passErr != null) return (ok: false, message: passErr);
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not configured');
    try {
      await AppwriteService.account.updatePassword(password: newPassword, oldPassword: oldPassword);
      return (ok: true, message: 'Password updated successfully');
    } on AppwriteException catch (e) {
      return (ok: false, message: _friendly(e));
    } catch (e) {
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
