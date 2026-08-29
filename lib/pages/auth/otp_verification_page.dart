import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../appwrite/auth_service.dart';
import '../../core/validators/auth_validators.dart';

/// OTP Verification + Reset Password page.
///
/// Route: /otp-verification?email=xxx
/// Step 1: verify 6-digit OTP (with countdown + resend)
/// Step 2: set new password via [AppwriteAuthService.resetPasswordWithOtp]
class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key, this.email});
  final String? email;
  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  bool _verified = false;
  String? _error;
  String? _info;
  bool _obscure = true;
  Timer? _timer;
  int _seconds = 0;

  String get _email => (widget.email ?? '').trim();

  @override
  void initState() {
    super.initState();
    _startCooldownIfNeeded();
  }

  void _startCooldownIfNeeded() {
    final r = AppwriteAuthService.resendCooldownRemaining(_email);
    if (r > 0) _startTimer(r);
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _seconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    final v = AuthValidators.validateOtp(_otpCtrl.text.trim());
    if (v != null) { setState(() => _error = v); return; }
    setState(() { _busy = true; _error = null; _info = null; });
    final res = await AppwriteAuthService.verifyResetOtp(_email, _otpCtrl.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.ok) { setState(() => _error = res.message); return; }
    setState(() { _verified = true; _info = 'OTP verified — set your new password'; });
  }

  Future<void> _resend() async {
    if (_busy || _seconds > 0) return;
    setState(() { _busy = true; _error = null; _info = null; });
    final res = await AppwriteAuthService.sendResetOtp(_email);
    if (!mounted) return;
    setState(() { _busy = false; });
    if (res.ok) {
      setState(() => _info = res.message);
      _startTimer(60);
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
                    'DEBUG OTP: ${res.debugOtp}',
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
    } else {
      setState(() => _error = res.message);
    }
  }

  Future<void> _reset() async {
    if (_busy) return;
    final pv = AuthValidators.validatePassword(_passCtrl.text.trim());
    if (pv != null) { setState(() => _error = pv); return; }
    final cv = AuthValidators.validateConfirm(_confirmCtrl.text.trim(), _passCtrl.text.trim());
    if (cv != null) { setState(() => _error = cv); return; }
    setState(() { _busy = true; _error = null; _info = null; });
    final res = await AppwriteAuthService.resetPasswordWithOtp(email: _email, newPassword: _passCtrl.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.ok) { setState(() => _error = res.message); return; }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_email.isEmpty || !AuthValidators.isValidEmail(_email)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verify OTP')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)), const SizedBox(height: 12), const Text('Missing email. Please start from Forgot Password.'), const SizedBox(height: 12), FilledButton(onPressed: () => context.go('/forgot-password'), child: const Text('Go to Forgot Password'))]))),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => _verified ? setState(() => _verified = false) : context.go('/forgot-password')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 18, offset: const Offset(0, 8))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (!_verified) ...[
                  Text('Enter OTP', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Code sent to $_email (expires in 10 min)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
                  const SizedBox(height: 18),
                  if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))), child: Row(children: [const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)))])),
                  if (_info != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD1FAE5))), child: Row(children: [const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF059669)), const SizedBox(width: 8), Expanded(child: Text(_info!, style: const TextStyle(color: Color(0xFF065F46), fontSize: 13)))])),
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(hintText: '000000', counterText: '', filled: true, fillColor: isDark ? const Color(0xFF1A1F24) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.4))),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _verify, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F), padding: const EdgeInsets.symmetric(vertical: 16), shape: const StadiumBorder()), child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.w800)))),
                  const SizedBox(height: 10),
                  Center(child: TextButton(onPressed: (_busy || _seconds > 0) ? null : _resend, child: Text(_seconds > 0 ? 'Resend OTP in ${_seconds}s' : 'Resend OTP', style: const TextStyle(fontWeight: FontWeight.w600)))),
                  if (_seconds > 0) Center(child: Text('Please wait before requesting a new code', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF9CA3AF), fontSize: 11))),
                ] else ...[
                  Text('Set new password', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('For $_email', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
                  const SizedBox(height: 18),
                  if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))), child: Row(children: [const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)))])),
                  if (_info != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD1FAE5))), child: Row(children: [const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF059669)), const SizedBox(width: 8), Expanded(child: Text(_info!, style: const TextStyle(color: Color(0xFF065F46), fontSize: 13)))])),
                  TextFormField(controller: _passCtrl, obscureText: _obscure, decoration: InputDecoration(hintText: 'New password', prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => _obscure = !_obscure)), filled: true, fillColor: isDark ? const Color(0xFF1A1F24) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 12),
                  TextFormField(controller: _confirmCtrl, obscureText: _obscure, decoration: InputDecoration(hintText: 'Confirm new password', prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)), filled: true, fillColor: isDark ? const Color(0xFF1A1F24) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _reset, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805), padding: const EdgeInsets.symmetric(vertical: 16), shape: const StadiumBorder()), child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w800)))),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
