import 'package:flutter/foundation.dart';

import 'web_file_saver.dart';

// For web platform
import 'dart:html' as html if (dart.library.io) 'dart:io';
import 'dart:typed_data';

class HtmlFileSaver implements WebFileSaver {
  @override
  void savePdf(List<int> bytes, String filename) {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Handle non-web platforms (mobile/desktop)
      // You might want to use the `printing` package or `path_provider` here
      throw UnsupportedError('PDF saving not supported on this platform');
    }
  }

  @override
  void saveExcel(List<int> bytes, String filename) {
    if (kIsWeb) {
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Handle non-web platforms (mobile/desktop)
      throw UnsupportedError('Excel saving not supported on this platform');
    }
  }
}
