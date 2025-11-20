import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfDownloadHelper {
  static Future<String?> downloadAndOpenPdf({
    required String url,
    required String reportType,
    required context,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // ✅ Save inside app documents directory
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$reportType-report.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath; // return path for PDFView
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
