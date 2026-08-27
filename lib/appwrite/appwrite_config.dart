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
/// Example run:
/// flutter run \
///   --dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1 \
///   --dart-define=APPWRITE_PROJECT_ID=65a1... \
///   --dart-define=APPWRITE_DATABASE_ID=hari_om_db \
///   --dart-define=APPWRITE_BUCKET_ID=product-images
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
      };
}
