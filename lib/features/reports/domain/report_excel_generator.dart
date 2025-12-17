import 'package:excel/excel.dart';
import '../../warehouse/domain/item.dart';
import '../../leave/domain/leave.dart';
import '../../attendance/domain/attendance.dart';

class ReportExcelGenerator {
  static Future<List<int>> generate(String title, Map<String, dynamic> data) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Header Style
    CellStyle headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);

    int row = 0;

    // Title Row
    sheet.cell(CellIndex.indexByString("A1")).value = TextCellValue(title);
    sheet.cell(CellIndex.indexByString("A1")).cellStyle = CellStyle(bold: true, fontSize: 16);
    row += 2; // Skip space

    // Content
    if (title == 'Stock Valuation') {
      final items = data['items'] as List<dynamic>; // List<Item>
      final totalValue = data['totalValue'];

      sheet.appendRow([TextCellValue('Total Asset Value'), DoubleCellValue(totalValue.toDouble())]);
      row++;

      List<String> headers = ['Item', 'Category', 'Stock', 'Price', 'Value'];
      _addHeader(sheet, headers, row, headerStyle);
      row++;

      for (var i in items) {
        final item = i as Item;
        sheet.appendRow([
          TextCellValue(item.name),
          TextCellValue(item.category),
          IntCellValue(item.stock),
          DoubleCellValue(item.price),
          DoubleCellValue(item.stock * item.price),
        ]);
        row++;
      }
    } else if (title == 'Reorder Plan') {
      final list = data['reorderList'] as List<dynamic>;
      final totalCost = data['totalCost'];

      sheet.appendRow([TextCellValue('Est. Reorder Cost'), DoubleCellValue(totalCost.toDouble())]);
      row++;

      List<String> headers = ['Item', 'Stock', 'Min', 'Order Qty', 'Est Cost'];
      _addHeader(sheet, headers, row, headerStyle);
      row++;

      for (var e in list) {
        final item = e['item'] as Item;
        sheet.appendRow([
          TextCellValue(item.name),
          IntCellValue(item.stock),
          IntCellValue(item.minStock),
          IntCellValue(e['gap']),
          DoubleCellValue(e['cost'].toDouble()),
        ]);
        row++;
      }
    } else if (title == 'Employee Performance') {
      final rankings = data['rankings'] as List<dynamic>;
      List<String> headers = ['Name', 'Days Present', 'Trans. Count', 'Score', 'Explanation'];
      _addHeader(sheet, headers, row, headerStyle);
      row++;

      for (var e in rankings) {
        final user = e['user'];
        sheet.appendRow([
          TextCellValue(user.name),
          IntCellValue(e['presentDays']),
          IntCellValue(e['transactionsCount']),
          DoubleCellValue(e['score']),
          TextCellValue(e['explanation']),
        ]);
        row++;
      }
    } else if (title == 'Leave Report') {
      final leaves = data['leaves'] as List<dynamic>; // List<Leave>
      List<String> headers = ['Reason', 'Check In', 'Check Out', 'Status', 'Date'];
      _addHeader(sheet, headers, row, headerStyle);
      row++;

      for (var item in leaves) {
        final l = item as Leave;
        sheet.appendRow([
          TextCellValue(l.reason),
          TextCellValue(l.startDate.toString().split(' ')[0]),
          TextCellValue(l.endDate.toString().split(' ')[0]),
          TextCellValue(l.status),
          TextCellValue(l.createdAt.toString().split(' ')[0]),
        ]);
        row++;
      }
    } else if (title == 'Attendance Report') {
      final list = data['data'] as List<dynamic>;
      List<String> headers = ['Name', 'Role', 'Date', 'In', 'Out', 'Note'];
      _addHeader(sheet, headers, row, headerStyle);
      row++;

      for (var e in list) {
        final att = e['attendance'] as Attendance;
        final role = e['role'] as String? ?? 'staff';
        sheet.appendRow([
          TextCellValue(att.userName ?? att.userId),
          TextCellValue(role),
          TextCellValue(att.date),
          TextCellValue(att.checkInTime != null ? att.checkInTime.toString().split(' ')[1].substring(0, 5) : '-'),
          TextCellValue(att.checkOutTime != null ? att.checkOutTime.toString().split(' ')[1].substring(0, 5) : '-'),
          TextCellValue(att.note ?? ''),
        ]);
        row++;
      }
    }
    // ... Add other types (Discontinued, Item Turnover) if needed

    return excel.save() ?? [];
  }

  static void _addHeader(Sheet sheet, List<String> headers, int rowIndex, CellStyle style) {
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = style;
    }
  }
}
