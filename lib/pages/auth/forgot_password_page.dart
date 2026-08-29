import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../appwrite/auth_service.dart';
import '../../core/validators/auth_validators.dart';

/// Dedicated Forgot Password page — Step 1 of OTP flow.
///
/// Route: /forgot-password
/// On success navigates to /otp-verification?email=xxx
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _busy = true; _error = null; _info = null; });
    final email = _emailCtrl.text.trim();
    final remaining = AppwriteAuthService.resendCooldownRemaining(email);
    if (remaining > 0) {
      setState(() { _busy = false; _error = 'Please wait ${remaining}s before resending'; });
      return;
    }
    final res = await AppwriteAuthService.sendResetOtp(email);
    if (!mounted) return;
    setState(() { _busy = false; });
    if (res.ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
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
                      'DEBUG OTP ID: ${res.otpId ?? "N/A"} | OTP: ${res.debugOtp}  (email not configured)',
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
        final otpIdParam = res.otpId != null ? '&otpId=${Uri.encodeComponent(res.otpId!)}' : '';
        context.go('/otp-verification?email=${Uri.encodeComponent(email)}$otpIdParam');
      }
    } else {
      setState(() => _error = res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/login')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14181B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF00C805).withValues(alpha: 0.12), shape: BoxShape.circle), child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF00C805))),
                  const SizedBox(height: 12),
                  Text('Reset your password', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Enter your registered email. We\'ll send a 6-digit OTP.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
                  const SizedBox(height: 18),
                  if (_error != null)
                    Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))), child: Row(children: [const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)))])),
                  if (_info != null)
                    Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD1FAE5))), child: Row(children: [const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF059669)), const SizedBox(width: 8), Expanded(child: Text(_info!, style: const TextStyle(color: Color(0xFF065F46), fontSize: 13)))])),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthValidators.validateEmail,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF2E7D32), size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A1F24) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _send,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805), padding: const EdgeInsets.symmetric(vertical: 16), shape: const StadiumBorder()),
                      child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send OTP', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(child: TextButton(onPressed: () => context.go('/login'), child: const Text('Back to Login'))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
