import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '_web_downloader.dart' if (dart.library.io) '_stub_downloader.dart';

/// Utility for exporting data tables to an Excel (.xlsx) file.
///
/// On web (the primary target), the file is immediately downloaded via the
/// browser's anchor-click download mechanism.
class ExportService {
  ExportService._();

  static Future<void> exportToExcel({
    required BuildContext context,
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    if (rows.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data to export'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final excel = Excel.createExcel();
    // Remove the default 'Sheet1' and create our named sheet
    final sheetName = 'Data';
    final sheet = excel[sheetName];
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Header row
    sheet.appendRow(
      headers.map<CellValue>((h) => TextCellValue(h)).toList(),
    );

    // Data rows
    for (final row in rows) {
      sheet.appendRow(
        row.map<CellValue>((cell) {
          if (cell == null) return TextCellValue('');
          if (cell is int) return IntCellValue(cell);
          if (cell is double) return DoubleCellValue(cell);
          if (cell is bool) return TextCellValue(cell ? 'Yes' : 'No');
          return TextCellValue(cell.toString());
        }).toList(),
      );
    }

    final bytes = excel.encode();
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate Excel file'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fileNameWithDate = '${fileName}_$date.xlsx';

    downloadFile(bytes, fileNameWithDate);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Saved to Downloads: $fileNameWithDate'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}
