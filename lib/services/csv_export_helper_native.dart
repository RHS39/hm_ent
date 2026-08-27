import 'dart:io';
import 'dart:typed_data';

Future<void> downloadCsvFile(Uint8List bytes, String fileName) async {
  final file = File(fileName);
  await file.writeAsBytes(bytes);
}
