import 'dart:typed_data';

import 'csv_export_helper_native.dart'
    if (dart.library.js_interop) 'csv_export_helper_web.dart' as impl;

Future<void> downloadCsvFile(Uint8List bytes, String fileName) {
  return impl.downloadCsvFile(bytes, fileName);
}
