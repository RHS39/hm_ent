import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/subscription_service.dart';
import '../widgets/app_header.dart';

/// Verification Status page — shown when user clicks email link
/// Route: /verify-email?token=YOUR_TOKEN
///
/// Handles success / invalid / expired states.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, this.token});
  final String? token;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _loading = true;
  bool _success = false;
  String? _email;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    final t = widget.token?.trim() ?? '';
    if (t.isEmpty) {
      setState(() {
        _loading = false;
        _success = false;
        _error = 'Missing verification token. Please use the link from your email.';
      });
      return;
    }
    final res = await SubscriptionService.instance.verifyToken(t);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = res.success;
      _email = res.email;
      _error = res.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppHeader(
        title: 'Email Verification',
        subtitle: 'Hari Om Traders',
        actions: [
          IconButton(icon: const Icon(Icons.home_outlined), tooltip: 'Home', onPressed: () => context.go('/')),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14181B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.18 : 0.05), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: _loading
                  ? Column(children: [
                      const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF00C805))),
                      const SizedBox(height: 16),
                      Text('Verifying your email…', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Token: ${(widget.token ?? '').characters.take(12).toString()}…', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
                    ])
                  : _success
                      ? Column(children: [
                          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF00C805).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.verified_rounded, color: Color(0xFF00C805), size: 32)),
                          const SizedBox(height: 16),
                          Text('You’re verified! 🎉', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
                          const SizedBox(height: 8),
                          Text(
                            _email != null ? 'Thanks — $_email is now subscribed. You’ll get farm-fresh drops & offers (max 2×/month).' : 'Thanks — your email is now subscribed.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : const Color(0xFF6B7280), height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => context.go('/'),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: const StadiumBorder()),
                              child: const Text('Go to Home', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(onPressed: () => context.go('/products'), style: OutlinedButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Shop jaggery')),
                        ])
                      : Column(children: [
                          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 32)),
                          const SizedBox(height: 16),
                          Text('Verification failed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
                          const SizedBox(height: 8),
                          Text(_error ?? 'Invalid or expired link.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : const Color(0xFF6B7280), height: 1.5)),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => context.go('/'),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: const StadiumBorder()),
                              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(onPressed: _verify, child: const Text('Try again')),
                        ]),
            ),
          ),
        ),
      ),
    );
  }
}
