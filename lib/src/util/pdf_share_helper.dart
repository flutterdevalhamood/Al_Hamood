import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PdfShareHelper {
  static Future<void> sharePdf({
    required BuildContext context,
    required String pdfPath,
    String? subject,
    String? text,
  }) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(pdfPath)],
          subject: subject ?? 'PDF Report',
          text: text ?? 'Sharing PDF Report',
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF file not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
