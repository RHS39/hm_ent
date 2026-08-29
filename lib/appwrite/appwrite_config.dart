/// Appwrite configuration for Hari Om Traders.
///
/// Values are injected via --dart-define so secrets are not committed.
/// Fall back to placeholders that fail closed (isConfigured == false).
///
/// Setup steps (Appwrite Cloud or self-hosted):
/// 1. Create Project at https://cloud.appwrite.io (or self-hosted URL)
/// 2. Create Database + 3 Collections: products, subscribers, contact_messages
/// 3. Create Storage Bucket: product-images (public)
/// 4. Copy IDs below and pass via --dart-define or set defaultValue.
///
/// Gmail API Setup:
/// 1. Enable Gmail API in Google Cloud Console
/// 2. Create OAuth 2.0 Client ID (Web application)
/// 3. Add authorized JavaScript origins and redirect URIs
/// 4. Pass GMAIL_CLIENT_ID and GMAIL_SENDER_EMAIL via --dart-define
///
/// Example run:
/// flutter run \
///   --dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1 \
///   --dart-define=APPWRITE_PROJECT_ID=65a1... \
///   --dart-define=APPWRITE_DATABASE_ID=hari_om_db \
///   --dart-define=APPWRITE_BUCKET_ID=product-images \
///   --dart-define=GMAIL_CLIENT_ID=your-client-id.apps.googleusercontent.com \
///   --dart-define=GMAIL_SENDER_EMAIL=your@gmail.com
class AppwriteConfig {
  /// Appwrite endpoint — e.g. https://cloud.appwrite.io/v1 or http://localhost/v1
  static const String endpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://cloud.appwrite.io/v1',
  );

  /// Project ID from Appwrite Console > Project Settings
  static const String projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '6a8c0d2c001da8c48b83',
  );

  /// Database ID (create in Appwrite Console > Databases)
  static const String databaseId = String.fromEnvironment(
    'APPWRITE_DATABASE_ID',
    defaultValue: 'hari_om_db',
  );

  // ── Collection IDs ──
  static const String productsCollectionId = String.fromEnvironment(
    'APPWRITE_PRODUCTS_COLLECTION_ID',
    defaultValue: 'products',
  );

  static const String subscribersCollectionId = String.fromEnvironment(
    'APPWRITE_SUBSCRIBERS_COLLECTION_ID',
    defaultValue: 'subscribers',
  );

  static const String contactMessagesCollectionId = String.fromEnvironment(
    'APPWRITE_CONTACT_COLLECTION_ID',
    defaultValue: 'contact_messages',
  );

  static const String usersCollectionId = String.fromEnvironment(
    'APPWRITE_USERS_COLLECTION_ID',
    defaultValue: 'users',
  );

  static const String pendingSubscriptionsCollectionId = String.fromEnvironment(
    'APPWRITE_PENDING_SUBSCRIPTIONS_COLLECTION_ID',
    defaultValue: 'pending_subscriptions',
  );

  /// Storage bucket ID for product images
  static const String bucketId = String.fromEnvironment(
    'APPWRITE_BUCKET_ID',
    defaultValue: 'product-images',
  );

  // ── Gmail API Configuration (legacy OAuth — client-side popup) ──
  /// Gmail OAuth 2.0 Client ID from Google Cloud Console.
  static const String gmailClientId = String.fromEnvironment(
    'GMAIL_CLIENT_ID',
    defaultValue: '511165041441-c00b9bstouq91ml3murntbqhcanr41au.apps.googleusercontent.com',
  );

  /// Gmail sender email address (the account that sends verification emails).
  static const String gmailSenderEmail = String.fromEnvironment(
    'GMAIL_SENDER_EMAIL',
    defaultValue: '',
  );

  /// Whether Gmail API credentials are configured.
  static bool get isGmailConfigured =>
      gmailClientId.isNotEmpty && gmailSenderEmail.isNotEmpty;

  // ── Gmail SMTP via App Password (for OTP — direct SMTP, no OAuth popup) ──
  /// Gmail address that owns the App Password (must match password account).
  /// Configured to rohitft20@gmail.com for this project.
  /// Override via --dart-define=GMAIL_SMTP_EMAIL=you@gmail.com
  static const String gmailSmtpEmail = String.fromEnvironment('GMAIL_SMTP_EMAIL', defaultValue: 'rohitft20@gmail.com');

  /// Gmail App Password for rohitft20@gmail.com (16 chars: "nrcppvuxywvttyvj").
  /// Paired with GMAIL_SMTP_EMAIL=rohitft20@gmail.com.
  /// Inject via --dart-define=GMAIL_APP_PASSWORD="nrcppvuxywvttyvj"
  static const String gmailAppPassword = String.fromEnvironment('GMAIL_APP_PASSWORD', defaultValue: 'nrcppvuxywvttyvj');

  /// Effective SMTP sender (resolved fallback).
  static String get effectiveGmailSmtpEmail {
    if (gmailSmtpEmail.trim().isNotEmpty) return gmailSmtpEmail.trim();
    if (gmailSenderEmail.trim().isNotEmpty) return gmailSenderEmail.trim();
    if (mailFromEmail.trim().isNotEmpty) return mailFromEmail.trim();
    return '';
  }

  /// Sanitized App Password (spaces removed).
  static String get gmailAppPasswordSanitized => gmailAppPassword.replaceAll(' ', '').trim();

  static bool get isGmailSmtpConfigured =>
      gmailAppPasswordSanitized.isNotEmpty && effectiveGmailSmtpEmail.contains('@');

  // ── Transactional Mail API (preferred for OTP — server-side, no popup) ──
  /// Provider hint: resend | sendgrid | brevo | generic | appwrite_function | auto
  static const String mailProvider = String.fromEnvironment('MAIL_PROVIDER', defaultValue: 'auto');

  /// API key / token for the mail provider (Resend, SendGrid, Brevo, or custom).
  /// For Appwrite Functions: create an API key in Appwrite Console > Project > API Keys
  /// with scopes: functions.read, functions.write
  /// Never commit — inject via --dart-define.
  static const String mailApiKey = String.fromEnvironment('MAIL_API_KEY', defaultValue: '');

  /// Full API URL. Examples:
  ///  Resend: https://api.resend.com/emails
  ///  SendGrid: https://api.sendgrid.com/v3/mail/send
  ///  Brevo: https://api.brevo.com/v3/smtp/email
  ///  Generic: https://your-backend.com/api/send-email
  ///  Appwrite Function: https://cloud.appwrite.io/v1/functions/<funcId>/executions
  ///  Local relay: http://localhost:8080/send-email (run: dart run tools/smtp_server.dart)
  static const String mailApiUrl = String.fromEnvironment('MAIL_API_URL', defaultValue: 'http://localhost:8080/send-email');

  /// Verified sender email (must be verified in provider dashboard).
  static const String mailFromEmail = String.fromEnvironment('MAIL_FROM_EMAIL', defaultValue: 'noreply@hariomtraders.com');

  /// Sender display name.
  static const String mailFromName = String.fromEnvironment('MAIL_FROM_NAME', defaultValue: 'Hari Om Traders');

  static bool get isMailApiConfigured {
    if (mailApiUrl.isEmpty) return false;
    // Local relay or Appwrite Functions — no API key needed
    if (mailApiUrl.contains('localhost') || mailApiUrl.contains('/functions/')) return true;
    // For other providers: need API key + from email
    return mailApiKey.isNotEmpty && mailFromEmail.isNotEmpty;
  }

  // ── email_auth package (OTP via email_auth Node server) ──
  /// Remote server URL for email_auth. Deploy: https://github.com/saran-surya/email_auth_node
  /// If empty, package uses default test server (limited 30 mails, not for production).
  static const String emailAuthServer = String.fromEnvironment('EMAIL_AUTH_SERVER', defaultValue: '');

  /// Server key for email_auth remote server (if required by your deployment).
  static const String emailAuthServerKey = String.fromEnvironment('EMAIL_AUTH_SERVER_KEY', defaultValue: '');

  static bool get isEmailAuthConfigured => emailAuthServer.isNotEmpty;

  /// Whether real credentials are configured.
  static bool get isConfigured =>
      !projectId.contains('YOUR_APPWRITE') &&
      projectId.isNotEmpty &&
      endpoint.startsWith('http') &&
      databaseId.isNotEmpty;

  /// Debug map for logging (no secrets — projectId is safe to log).
  static Map<String, String> get debugInfo => {
        'endpoint': endpoint,
        'projectId': projectId,
        'databaseId': databaseId,
        'productsCollection': productsCollectionId,
        'subscribersCollection': subscribersCollectionId,
        'contactCollection': contactMessagesCollectionId,
        'usersCollection': usersCollectionId,
        'pendingSubscriptionsCollection': pendingSubscriptionsCollectionId,
        'bucketId': bucketId,
        'isConfigured': isConfigured.toString(),
        'isGmailConfigured': isGmailConfigured.toString(),
        'isGmailSmtpConfigured': isGmailSmtpConfigured.toString(),
        'effectiveGmailSmtpEmail': effectiveGmailSmtpEmail,
        'isMailApiConfigured': isMailApiConfigured.toString(),
        'mailProvider': mailProvider,
        'mailApiUrl': mailApiUrl,
        'mailFromEmail': mailFromEmail,
        'isEmailAuthConfigured': isEmailAuthConfigured.toString(),
        'emailAuthServer': emailAuthServer,
      };
}
