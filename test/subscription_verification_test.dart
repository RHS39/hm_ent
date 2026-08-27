import 'package:flutter_test/flutter_test.dart';
import 'package:hm_ent/appwrite/pending_subscription_repository.dart';
import 'package:hm_ent/services/email_service.dart';
import 'package:hm_ent/services/subscription_service.dart';

void main() {
  group('Email verification flow', () {
    setUp(() {
      SubscriptionService.instance.clearMock();
      PendingSubscriptionRepository.clearMock();
      EmailService.instance.clear();
    });

    test('Submitting unverified email does not exist in subscribers initially', () async {
      const email = 'newuser@example.com';
      expect(SubscriptionService.instance.isMockSubscribed(email), isFalse);

      final res = await SubscriptionService.instance.requestSubscription(email: email);
      expect(res.success, isTrue);
      expect(res.verificationSent, isTrue);
      expect(res.alreadySubscribed, isFalse);
      expect(res.token, isNotNull);
      // Should still not be in subscribers until verified
      expect(SubscriptionService.instance.isMockSubscribed(email), isFalse);
    });

    test('Record created in pending table and email queued', () async {
      const email = 'pending@example.com';
      final res = await SubscriptionService.instance.requestSubscription(email: email);
      expect(res.token, isNotNull);
      final token = res.token!;

      // Pending should exist
      final pending = await PendingSubscriptionRepository.findByToken(token);
      expect(pending, isNotNull);
      expect(pending!['email'], email.toLowerCase());
      expect(pending['verification_token'], token);
      expect(pending['expires_at'], isNotNull);
      // Expiry should be ~24h in future
      final expires = DateTime.parse(pending['expires_at'] as String);
      final diff = expires.difference(DateTime.now().toUtc());
      expect(diff.inHours, greaterThanOrEqualTo(23));
      expect(diff.inHours, lessThanOrEqualTo(25));

      // Email queued
      expect(EmailService.instance.outbox.length, 1);
      final queued = EmailService.instance.outbox.first;
      expect(queued['email'], email.toLowerCase());
      expect(queued['token'], token);
      expect(queued['link'], contains(token));
      expect(queued['link'], contains('/verify-email?token='));
      expect(EmailService.instance.lastVerificationLink, isNotNull);
      expect(EmailService.instance.lastRecipient, email.toLowerCase());
    });

    test('Successfully verifying via token inserts into subscribers and deletes pending', () async {
      const email = 'verifyme@example.com';
      final req = await SubscriptionService.instance.requestSubscription(email: email);
      final token = req.token!;
      expect(SubscriptionService.instance.isMockSubscribed(email), isFalse);

      // Verify pending exists before verification
      expect(await PendingSubscriptionRepository.findByToken(token), isNotNull);

      final verifyRes = await SubscriptionService.instance.verifyToken(token);
      expect(verifyRes.success, isTrue);
      expect(verifyRes.email, email.toLowerCase());
      expect(verifyRes.error, isNull);

      // Now should be in subscribers
      expect(SubscriptionService.instance.isMockSubscribed(email), isTrue);

      // Pending should be deleted
      expect(await PendingSubscriptionRepository.findByToken(token), isNull);
      expect(await PendingSubscriptionRepository.findByEmail(email), isNull);

      // Outbox cleaned
      expect(EmailService.instance.outbox.where((m) => m['token'] == token).length, 0);
    });

    test('Already subscribed email returns alreadySubscribed without creating pending', () async {
      const email = 'already@example.com';
      // First request + verify to make it subscribed
      final first = await SubscriptionService.instance.requestSubscription(email: email);
      await SubscriptionService.instance.verifyToken(first.token!);
      expect(SubscriptionService.instance.isMockSubscribed(email), isTrue);
      EmailService.instance.clear();

      // Second request should short-circuit
      final second = await SubscriptionService.instance.requestSubscription(email: email);
      expect(second.success, isTrue);
      expect(second.alreadySubscribed, isTrue);
      expect(second.verificationSent, isFalse);
      expect(second.token, isNull);
      // No new pending/email
      expect(EmailService.instance.outbox.length, 0);
      expect(await PendingSubscriptionRepository.findByEmail(email), isNull);
    });

    test('Handling invalid token returns error', () async {
      final res = await SubscriptionService.instance.verifyToken('invalid-token-12345');
      expect(res.success, isFalse);
      expect(res.error, contains('Invalid'));
      expect(res.email, isNull);
    });

    test('Handling expired token returns expired error and deletes pending', () async {
      const email = 'expired@example.com';
      // Manually create pending with past expiry
      final expiredToken = 'expired_token_test_123';
      final pastExpiry = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      await PendingSubscriptionRepository.createPending(
        email: email,
        token: expiredToken,
        expiresAt: pastExpiry,
      );
      expect(await PendingSubscriptionRepository.findByToken(expiredToken), isNotNull);
      expect(PendingSubscriptionRepository.isExpired((await PendingSubscriptionRepository.findByToken(expiredToken))!), isTrue);

      final res = await SubscriptionService.instance.verifyToken(expiredToken);
      expect(res.success, isFalse);
      expect(res.error, contains('expired'));
      // Pending should be deleted after expired attempt
      expect(await PendingSubscriptionRepository.findByToken(expiredToken), isNull);
      // Should not be subscribed
      expect(SubscriptionService.instance.isMockSubscribed(email), isFalse);
    });

    test('Invalid email format rejected before pending creation', () async {
      final res = await SubscriptionService.instance.requestSubscription(email: 'not-an-email');
      expect(res.success, isFalse);
      expect(res.error, contains('valid email'));
      expect(EmailService.instance.outbox.length, 0);
      expect(await PendingSubscriptionRepository.findByEmail('not-an-email'), isNull);
    });

    test('Email validation utility works', () {
      expect(SubscriptionService.instance.isValidEmail('test@example.com'), isTrue);
      expect(SubscriptionService.instance.isValidEmail(' Test+ALIAS@EXAMPLE.co.in '), isTrue);
      expect(SubscriptionService.instance.isValidEmail('bad@'), isFalse);
      expect(SubscriptionService.instance.isValidEmail(''), isFalse);
    });
  });
}
