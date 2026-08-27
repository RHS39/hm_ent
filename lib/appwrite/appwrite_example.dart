import 'package:flutter/material.dart';
import 'appwrite_client.dart';

/// Example widget showing Appwrite connection + query.
class AppwriteExample extends StatefulWidget {
  const AppwriteExample({super.key});

  @override
  State<AppwriteExample> createState() => _AppwriteExampleState();
}

class _AppwriteExampleState extends State<AppwriteExample> {
  String _status = 'Not connected';

  Future<void> _testConnection() async {
    if (!AppwriteService.isInitialized) {
      setState(() => _status = 'Appwrite not initialized — set --dart-define APPWRITE_PROJECT_ID / ENDPOINT');
      return;
    }
    try {
      final docs = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'products',
      );
      setState(() => _status = 'Connected! Documents: ${docs.total}');
    } catch (e) {
      setState(() => _status = 'Query failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appwrite', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_status, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: _testConnection, child: const Text('Test Connection')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
