import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../warehouse/domain/item.dart';
import '../../leave/domain/leave.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../settings/data/settings_dao.dart';
import '../../../core/services/appwrite_service.dart';
import '../../../core/config/appwrite_config.dart';

class ReportPdfGenerator {
  static Future<Uint8List> generate(String title, Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Fetch Config for Header
    pw.MemoryImage? headerImage;
    try {
      final dao = SettingsDao(AppwriteService.instance);
      final config = await dao.getSignatureConfig();
      if (config['headerFileId'] != null) {
        final bytes = await AppwriteService.instance.storage.getFileDownload(
          bucketId: AppwriteConfig.storageBucketId,
          fileId: config['headerFileId']!,
        );
        headerImage = pw.MemoryImage(bytes);
      }
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [_buildHeader(title, headerImage), pw.SizedBox(height: 20), _buildContent(title, data)],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: '$title.pdf');
    return await pdf.save();
  }

  static pw.Widget _buildHeader(String title, pw.MemoryImage? headerImage) {
    return pw.Header(
      level: 0,
      child: pw.Column(
        children: [
          if (headerImage != null)
            pw.Image(headerImage, width: 500)
          else
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          if (headerImage != null) pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (headerImage != null)
                pw.Text(
                  title,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ), // Show title small if header exists
              pw.Text('Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildContent(String title, Map<String, dynamic> data) {
    final dateFormatter = DateFormat('dd MMM yyyy');

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
            pw.TableHelper.fromTextArray(
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
            pw.TableHelper.fromTextArray(
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
            pw.TableHelper.fromTextArray(
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
        return pw.TableHelper.fromTextArray(
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
        return pw.TableHelper.fromTextArray(
          headers: ['Name', 'Days Present', 'Trans. Count', 'Score', 'Insight'],
          data: rankings.map((e) {
            final user = e['user'];
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
        // Now leaves is list of Map {'leave': Leave, 'name': String}

        return pw.TableHelper.fromTextArray(
          headers: ['Name', 'Reason', 'Start', 'End', 'Status', 'Prior Att.'],
          data: leaves.map((e) {
            final leave = e['leave'] as Leave;
            final name = e['name'] as String;
            final prev = e['prevWorkDays'] ?? 0;

            // Safe date formatting
            String start = leave.startDate;
            String end = leave.endDate;
            try {
              start = dateFormatter.format(DateTime.parse(leave.startDate));
              end = dateFormatter.format(DateTime.parse(leave.endDate));
            } catch (_) {}

            return [name, leave.reason, start, end, leave.status, '$prev days'];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
        );
      }

      if (title == 'Attendance Report') {
        final list = data['data'] as List<dynamic>;
        return pw.TableHelper.fromTextArray(
          headers: ['Name', 'Role', 'Date', 'In', 'Out'],
          data: list.map((e) {
            final att = e['attendance'];
            final role = e['role'] ?? 'staff';

            // Format check-in/out
            String inTime = '-';
            String outTime = '-';
            String dateStr = att.date;

            try {
              dateStr = dateFormatter.format(DateTime.parse(att.date));
            } catch (_) {}

            if (att.checkInTime != null) {
              inTime = DateFormat('HH:mm').format(att.checkInTime!);
            }
            if (att.checkOutTime != null) {
              outTime = DateFormat('HH:mm').format(att.checkOutTime!);
            }

            return [att.userName ?? att.userId, role, dateStr, inTime, outTime];
          }).toList(),
        );
      }
      if (title == 'Payslip') {
        return _buildPayslipContent(data);
      }
    } catch (e) {
      return pw.Text('Error rendering PDF content: $e');
    }

    return pw.Text('Unknown Report Type');
  }

  static pw.Widget _buildPayslipContent(Map<String, dynamic> data) {
    final payrollJson = data['payroll'];
    // Re-hydrate objects manually as we might be passing raw JSON or object.
    // Assuming 'payroll' is the map from Payroll.toJson().
    // It includes 'detail' map.

    final userName = data['userName'] ?? 'Karyawan';
    final period = '${payrollJson['periodStart']} - ${payrollJson['periodEnd']}';

    final detail = payrollJson['detail'] is String ? {} : (payrollJson['detail'] as Map<String, dynamic>);
    // Assuming backend service passed it correctly. BUT repo sanitized to string if JSON.
    // If we are calling from UI using Payroll object, check if we passed object or JSON map.
    // Let's assume we passed Map<String, dynamic> representing Payroll.

    final breakdown = detail['breakdown'] ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text('SLIP GAJI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [pw.Text('Nama: $userName'), pw.Text('Periode: $period')],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),

        _buildRow('Gaji Pokok', (payrollJson['baseSalary'] ?? 0)),
        pw.SizedBox(height: 10),
        pw.Text('Penerimaan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        _buildRow('  Tunjangan Transport', breakdown['transport'] ?? 0),
        _buildRow('  Uang Makan', breakdown['meal'] ?? 0),
        _buildRow('  Lembur', breakdown['totalOvertime'] ?? 0),
        _buildRow(
          'Total Penerimaan',
          (payrollJson['totalAllowance'] ?? 0) + (payrollJson['totalOvertime'] ?? 0),
          isBold: true,
        ),

        pw.SizedBox(height: 10),
        pw.Text(
          'Potongan:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red),
        ),
        _buildRow('  Terlambat', breakdown['lateDeduction'] ?? 0),
        _buildRow('  Absen', breakdown['absentDeduction'] ?? 0),
        _buildRow('Total Potongan', payrollJson['totalDeduction'] ?? 0, isBold: true),

        pw.Divider(),
        _buildRow('GAJI BERSIH', payrollJson['netSalary'] ?? 0, isBold: true, fontSize: 16),
        pw.SizedBox(height: 40),

        // Signature Area
        _buildSignatureSection(data),
      ],
    );
  }

  static pw.Widget _buildRow(String label, dynamic value, {bool isBold = false, double fontSize = 12}) {
    double val = 0;
    if (value is int) val = value.toDouble();
    if (value is double) val = value;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: fontSize),
        ),
        pw.Text(
          CurrencyFormatter.format(val),
          style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: fontSize),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureSection(Map<String, dynamic> data) {
    final signerName = data['signerName'] ?? 'Admin';
    final signatureBytes = data['signatureBytes'] as Uint8List?;
    final stampBytes = data['stampBytes'] as Uint8List?;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          children: [
            pw.Text('Mengetahui,'),
            pw.SizedBox(height: 10),
            pw.Container(
              width: 150,
              height: 80,
              child: pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  if (stampBytes != null)
                    pw.Opacity(opacity: 0.7, child: pw.Image(pw.MemoryImage(stampBytes), width: 80)),
                  if (signatureBytes != null) pw.Image(pw.MemoryImage(signatureBytes), width: 100),
                ],
              ),
            ),
            pw.Text(
              signerName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
            ),
          ],
        ),
      ],
    );
  }
}
