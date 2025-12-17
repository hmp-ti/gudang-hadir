import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../warehouse/domain/item.dart';
import '../../../core/utils/currency_formatter.dart';

class ReportPdfGenerator {
  static Future<Uint8List> generate(String title, Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [_buildHeader(title), pw.SizedBox(height: 20), _buildContent(title, data)],
      ),
    );

    // Save and Open
    // On Android/iOS: Printing.layoutPdf or Printing.sharePdf
    // The user requirement says "report yang bisa dijadikan PDF". Sharing is best.
    await Printing.sharePdf(bytes: await pdf.save(), filename: '$title.pdf');
    return await pdf.save();
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Generated: ${DateTime.now().toString().split('.')[0]}'),
        ],
      ),
    );
  }

  static pw.Widget _buildContent(String title, Map<String, dynamic> data) {
    try {
      if (title == 'Stock Valuation') {
        final items = data['items'] as List<Item>;
        final totalValue = data['totalValue'] as num;

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Total Asset Value: ${CurrencyFormatter.format(totalValue.toDouble())}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Item', 'Category', 'Stock', 'Price', 'Value'],
              data: items
                  .map(
                    (e) => [
                      e.name,
                      e.category,
                      e.stock.toString(),
                      CurrencyFormatter.format(e.price),
                      CurrencyFormatter.format(e.stock * e.price),
                    ],
                  )
                  .toList(),
            ),
          ],
        );
      }

      if (title == 'Reorder Plan') {
        final list = data['reorderList'] as List<Map<String, dynamic>>;
        final totalCost = data['totalCost'] as num;

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Estimated Reorder Cost: ${CurrencyFormatter.format(totalCost.toDouble())}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Item', 'Stock', 'Min', 'Order Qty', 'Est Cost'],
              data: list.map((e) {
                final item = e['item'] as Item;
                return [
                  item.name,
                  item.stock.toString(),
                  item.minStock.toString(),
                  e['gap'].toString(),
                  CurrencyFormatter.format(e['cost']),
                ];
              }).toList(),
            ),
          ],
        );
      }

      if (title == 'Discontinued Stock') {
        final items = data['items'] as List<Item>;
        final val = data['totalValue'] as num;
        return pw.Column(
          children: [
            pw.Text('Dead Stock Value: ${CurrencyFormatter.format(val.toDouble())}'),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Item', 'Category', 'Stock', 'Price', 'Value'],
              data: items
                  .map(
                    (e) => [
                      e.name,
                      e.category,
                      e.stock.toString(),
                      CurrencyFormatter.format(e.price),
                      CurrencyFormatter.format(e.stock * e.price),
                    ],
                  )
                  .toList(),
            ),
          ],
        );
      }

      if (title == 'Item Turnover') {
        final items = data['items'] as List<Map<String, dynamic>>;
        return pw.Table.fromTextArray(
          headers: ['Item', 'Stock', 'Qty Moved', 'Turnover Rate'],
          data: items.map((e) {
            final item = e['item'] as Item;
            return [
              item.name,
              item.stock.toString(),
              e['qtyMoved'].toString(),
              (e['turnoverRate'] as double).toStringAsFixed(2),
            ];
          }).toList(),
        );
      }

      if (title == 'Employee Performance') {
        final rankings = data['rankings'] as List<Map<String, dynamic>>;
        return pw.Table.fromTextArray(
          headers: ['Name', 'Days Present', 'Trans. Count', 'Score', 'Insight'],
          data: rankings.map((e) {
            // Map User object? Or simply data map?
            // In ReportService we put 'user' as User object.
            final user = e['user']; // User type
            final name = user.name;
            return [
              name,
              e['presentDays'].toString(),
              e['transactionsCount'].toString(),
              (e['score'] as double).toStringAsFixed(1),
              e['explanation'] ?? '',
            ];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
        );
      }

      if (title == 'Leave Report') {
        final leaves = data['leaves'] as List<dynamic>;
        return pw.Table.fromTextArray(
          headers: ['Reason', 'Start', 'End', 'Status'],
          data: leaves.map((e) {
            // e is Leave object
            return [e.reason, e.startDate.toString().split(' ')[0], e.endDate.toString().split(' ')[0], e.status];
          }).toList(),
        );
      }

      if (title == 'Attendance Report') {
        final list = data['data'] as List<dynamic>;
        return pw.Table.fromTextArray(
          headers: ['Name', 'Role', 'Date', 'In', 'Out'],
          data: list.map((e) {
            final att = e['attendance'];
            final role = e['role'] ?? 'staff';
            return [
              att.userName ?? att.userId,
              role,
              att.date,
              att.checkInTime != null ? att.checkInTime.toString().split(' ')[1].substring(0, 5) : '-',
              att.checkOutTime != null ? att.checkOutTime.toString().split(' ')[1].substring(0, 5) : '-',
            ];
          }).toList(),
        );
      }
    } catch (e) {
      return pw.Text('Error rendering PDF content: $e');
    }

    return pw.Text('Unknown Report Type');
  }
}
