import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../appwrite/auth_service.dart';
import '../../core/validators/auth_validators.dart';
import '../../widgets/app_header.dart';

enum AuthMode { login, signup }

enum _ResetStep { none, email, otp, password }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialMode = AuthMode.login});
  final AuthMode initialMode;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late AuthMode _mode;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _info;

  // Forgot password OTP flow
  _ResetStep _resetStep = _ResetStep.none;
  String _resetEmail = '';
  String? _resetOtpId;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  bool get _canResend => _resendSeconds == 0 && !_busy;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppwriteAuthService.isLoggedIn && mounted) {
        context.go(AppwriteAuthService.isAdmin ? '/admin' : '/');
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final name = _nameCtrl.text.trim();
    final res = _mode == AuthMode.signup
        ? await AppwriteAuthService.signUp(name: name, email: email, password: pass)
        : await AppwriteAuthService.signIn(email: email, password: pass);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      setState(() => _info = res.message);
      if (_mode == AuthMode.login) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) context.go(AppwriteAuthService.isAdmin ? '/admin' : '/');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      }
    } else {
      setState(() => _error = res.message);
    }
  }

  // ── OTP Forgot Password Flow ──

  void _startForgotPassword() {
    final email = _emailCtrl.text.trim();
    setState(() {
      _resetStep = _ResetStep.email;
      _resetEmail = email;
      _error = null;
      _info = null;
    });
  }

  void _cancelReset() {
    setState(() {
      _resetStep = _ResetStep.none;
      _error = null;
      _info = null;
      _resetOtpId = null;
      _otpCtrl.clear();
    });
  }

  Future<void> _sendOtp() async {
    if (!_canResend) return;
    final email = _resetEmail.trim();
    final v = AuthValidators.validateEmail(email);
    if (v != null) {
      setState(() => _error = v);
      return;
    }
    // Service-level cooldown check as well
    final remaining = AppwriteAuthService.resendCooldownRemaining(email);
    if (remaining > 0) {
      setState(() => _error = 'Please wait ${remaining}s before resending');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final res = await AppwriteAuthService.sendResetOtp(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _info = res.ok ? res.message : null;
      _error = res.ok ? null : res.message;
      _resetStep = res.ok ? _ResetStep.otp : _resetStep;
      _resetOtpId = res.ok ? res.otpId : _resetOtpId;
    });
    if (res.ok) {
      _startResendCooldown();
      // Show debug OTP when email could not actually be sent (web / no provider)
      if (kDebugMode && res.debugOtp != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.amber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DEBUG OTP ID: ${res.otpId ?? "N/A"} | OTP: ${res.debugOtp}  (email not configured — check console)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A1F24),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _verifyOtpAndReset() async {
    final otp = _otpCtrl.text.trim();
    final v = AuthValidators.validateOtp(otp);
    if (v != null) {
      setState(() => _error = v);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final verifyRes = await AppwriteAuthService.verifyResetOtp(_resetEmail, otp);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!verifyRes.ok) {
      setState(() => _error = verifyRes.message);
      return;
    }
    // OTP verified — move to new-password step (no navigation needed)
    setState(() {
      _info = 'OTP verified — set your new password';
      _resetStep = _ResetStep.password;
    });
  }

  Future<void> _confirmNewPassword() async {
    final p1 = _passCtrl.text.trim();
    final p2 = _confirmCtrl.text.trim();
    final pv = AuthValidators.validatePassword(p1);
    if (pv != null) {
      setState(() => _error = pv);
      return;
    }
    final cv = AuthValidators.validateConfirm(p2, p1);
    if (cv != null) {
      setState(() => _error = cv);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final res = await AppwriteAuthService.resetPasswordWithOtp(email: _resetEmail, newPassword: p1);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.ok) {
      setState(() => _error = res.message);
      return;
    }
    setState(() {
      _info = res.message;
      _resetStep = _ResetStep.none;
      _otpCtrl.clear();
      _passCtrl.clear();
      _confirmCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? const Color(0xFF1A1F24) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 360 ? 12 : 16,
              24,
              MediaQuery.sizeOf(context).width < 360 ? 12 : 16,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<int>(
                      icon: Icon(Icons.menu, color: isDark ? Colors.white : const Color(0xFF0B0E0F)),
                      offset: const Offset(0, -4),
                      onSelected: (v) {
                        if (v == 0) {
                          final isCurrentlyDark = themeController.value == ThemeMode.dark;
                          themeController.value = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
                        }
                        if (v == 1) context.go('/');
                      },
                      itemBuilder: (_) => [
                        _ThemeMenuItem(),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 1,
                          child: Row(children: [Icon(Icons.home_outlined, size: 18), SizedBox(width: 10), Text('Back to Home')]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => context.go('/'),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset('assets/img/logo.png', width: 36, height: 36,
                          errorBuilder: (_, __, ___) => Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(color: Color(0xFF00C805), shape: BoxShape.circle),
                              child: const Icon(Icons.spa, size: 16, color: Colors.white))),
                      const SizedBox(width: 10),
                      Text('Hari Om Traders',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14181B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Mode Tabs (hidden during reset flow) ──
                        if (_resetStep == _ResetStep.none) ...[
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                            ),
                            child: Row(children: [
                              Expanded(child: _ModeTab(label: 'Log in', selected: _mode == AuthMode.login, onTap: () => setState(() => _mode = AuthMode.login))),
                              Expanded(child: _ModeTab(label: 'Sign up', selected: _mode == AuthMode.signup, onTap: () => setState(() => _mode = AuthMode.signup))),
                            ]),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // ── Header ──
                        if (_resetStep == _ResetStep.none)
                          Text(_mode == AuthMode.login ? 'Welcome back' : 'Create account',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0B0E0F)))
                        else ...[
                          Row(children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                              onPressed: _busy ? null : _cancelReset,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            Text('Reset password', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
                          ]),
                        ],
                        const SizedBox(height: 4),
                        if (_resetStep == _ResetStep.none)
                          Text(_mode == AuthMode.login ? 'Log in to track orders and save favorites' : 'Join 10k+ families enjoying organic jaggery',
                              style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280)))
                        else if (_resetStep == _ResetStep.email)
                          Text('Enter your email and we\'ll send you a verification code.',
                              style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280)))
                        else if (_resetStep == _ResetStep.otp)
                          Text('Enter the 6-digit code sent to $_resetEmail',
                              style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280)))
                        else
                          Text('Set your new password for $_resetEmail',
                              style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
                        const SizedBox(height: 18),

                        // ── Error / Info ──
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
                            child: Row(children: [
                              const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)))
                            ]),
                          ),
                        if (_info != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD1FAE5))),
                            child: Row(children: [
                              const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF059669)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_info!, style: TextStyle(color: Color(0xFF065F46), fontSize: 13)))
                            ]),
                          ),

                        // ── Step: Login/Signup Form ──
                        if (_resetStep == _ResetStep.none) ...[
                          Form(
                            key: _formKey,
                            child: Column(children: [
                              if (_mode == AuthMode.signup) ...[
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: _dec('Full name', Icons.person_outline),
                                  validator: (v) => v == null || v.trim().length < 2 ? 'Enter your name' : null,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _dec('Email address', Icons.alternate_email),
                                validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                decoration: _dec('Password', Icons.lock_outline,
                                    suffix: IconButton(
                                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                                        onPressed: () => setState(() => _obscure = !_obscure))),
                                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                              ),
                              if (_mode == AuthMode.signup) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscure,
                                  decoration: _dec('Confirm password', Icons.lock_outline),
                                  validator: (v) {
                                    if (_mode == AuthMode.signup && v != _passCtrl.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ],
                              if (_mode == AuthMode.login)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _busy ? null : _startForgotPassword,
                                    child: const Text('Forgot password?', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B0E0F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: _busy
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Text(_mode == AuthMode.login ? 'Log in' : 'Create account', style: const TextStyle(fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(child: Divider(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('or', style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
                            ),
                            Expanded(child: Divider(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                          ]),
                          const SizedBox(height: 14),
                          // Demo Admin
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      setState(() {
                                        _busy = true;
                                        _error = null;
                                        _info = null;
                                      });
                                      final res = await AppwriteAuthService.signInAsDummyAdmin();
                                      if (!mounted) return;
                                      setState(() => _busy = false);
                                      if (res.ok) {
                                        setState(() => _info = 'Logged in as admin');
                                        Future.delayed(const Duration(milliseconds: 600), () {
                                          if (mounted) context.go('/admin');
                                        });
                                      } else {
                                        setState(() => _error = res.message);
                                      }
                                    },
                              icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                              label: const Text('Demo Admin Login', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00C805),
                                side: const BorderSide(color: Color(0xFF00C805)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CredentialsBox(
                            label: 'Demo Admin Credentials',
                            email: 'admin@hariomtraders.com',
                            password: 'HariOm@2026',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          // Demo Customer
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      setState(() {
                                        _busy = true;
                                        _error = null;
                                        _info = null;
                                      });
                                      final res = await AppwriteAuthService.signInAsDummyCustomer();
                                      if (!mounted) return;
                                      setState(() => _busy = false);
                                      if (res.ok) {
                                        setState(() => _info = 'Logged in as customer');
                                        Future.delayed(const Duration(milliseconds: 600), () {
                                          if (mounted) context.go('/');
                                        });
                                      } else {
                                        setState(() => _error = res.message);
                                      }
                                    },
                              icon: const Icon(Icons.person_rounded, size: 18),
                              label: const Text('Demo Customer Login', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFF2563EB)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CredentialsBox(
                            label: 'Demo Customer Credentials',
                            email: 'customer@hariomtraders.com',
                            password: 'HariOm@2026',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          Center(child: TextButton(onPressed: () => context.go('/'), child: const Text('\u2190 Back to home'))),
                        ],

                        // ── Step: Enter Email for OTP ──
                        if (_resetStep == _ResetStep.email) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _resetEmail,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec('Email address', Icons.alternate_email),
                            onChanged: (v) => _resetEmail = v,
                            validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _sendOtp,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF00C805),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: const StadiumBorder(),
                              ),
                              child: _busy
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Send OTP', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],

                        // ── Step: Enter OTP ──
                        if (_resetStep == _ResetStep.otp) ...[
                          if (_resetOtpId != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('OTP ID', style: TextStyle(color: const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(_resetOtpId!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 6, color: isDark ? Colors.white : const Color(0xFF0B0E0F), fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w700),
                            decoration: _dec('000000', Icons.pin_outlined).copyWith(
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _verifyOtpAndReset,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0B0E0F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: const StadiumBorder(),
                              ),
                              child: _busy
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                   : const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Column(
                              children: [
                                TextButton(
                                  onPressed: _canResend ? _sendOtp : null,
                                  child: Text(
                                    _resendSeconds > 0 ? 'Resend OTP in ${_resendSeconds}s' : 'Resend OTP',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (_resendSeconds > 0)
                                  Text(
                                    'Please wait before requesting a new code',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF9CA3AF), fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // ── Step: New Password (after OTP verified) ──
                        if (_resetStep == _ResetStep.password) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: _dec('New password', Icons.lock_outline,
                                suffix: IconButton(
                                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                                    onPressed: () => setState(() => _obscure = !_obscure))),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscure,
                            decoration: _dec('Confirm new password', Icons.lock_outline),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _confirmNewPassword,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF00C805),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: const StadiumBorder(),
                              ),
                              child: _busy
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('By continuing you agree to Terms and Privacy',
                      style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white54 : const Color(0xFF9CA3AF), fontSize: 11),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: selected ? const Color(0xFF0B0E0F) : Colors.transparent, borderRadius: BorderRadius.circular(100)),
        child: Center(
            child: Text(label,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? Colors.white : const Color(0xFF6B7280)))),
      ),
    );
  }
}

class _CredentialsBox extends StatelessWidget {
  const _CredentialsBox({required this.label, required this.email, required this.password, required this.isDark});
  final String label;
  final String email;
  final String password;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
          ]),
          const SizedBox(height: 6),
          Text('Email: $email', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isDark ? Colors.white60 : const Color(0xFF374151))),
          Text('Password: $password', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isDark ? Colors.white60 : const Color(0xFF374151))),
        ],
      ),
    );
  }
}

class _ThemeMenuItem extends PopupMenuItem<int> {
  _ThemeMenuItem()
      : super(
          value: 0,
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController,
            builder: (context, mode, _) {
              final isDarkMode = mode == ThemeMode.dark;
              return Row(children: [
                Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, size: 18),
                const SizedBox(width: 10),
                Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
              ]);
            },
          ),
        );
}
