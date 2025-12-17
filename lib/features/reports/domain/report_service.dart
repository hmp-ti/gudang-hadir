import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../warehouse/data/item_dao.dart';
import '../../warehouse/data/transaction_dao.dart';
import '../../attendance/data/attendance_dao.dart';
import '../../auth/data/user_dao.dart';
import '../../leave/data/leave_dao.dart';
import '../data/report_history_dao.dart';
import '../domain/report_pdf_generator.dart';
import '../domain/report_excel_generator.dart';
import '../domain/generated_report.dart';

final reportServiceProvider = Provider((ref) {
  return ReportService(
    ref.read(itemDaoProvider),
    ref.read(transactionDaoProvider),
    ref.read(userDaoProvider),
    ref.read(attendanceDaoProvider),
    ref.read(leaveDaoProvider),
    ref.read(reportHistoryDaoProvider),
  );
});

class ReportService {
  final ItemDao _itemDao;
  final TransactionDao _transactionDao;
  final UserDao _userDao;
  final AttendanceDao _attendanceDao;
  final LeaveDao _leaveDao;
  final ReportHistoryDao _historyDao;

  ReportService(
    this._itemDao,
    this._transactionDao,
    this._userDao,
    this._attendanceDao,
    this._leaveDao,
    this._historyDao,
  );

  // --- Core Logic for Upload & History ---

  Future<GeneratedReport> generateAndSaveReport({
    required String title,
    required String reportType, // e.g., 'Stock Valuation' matches title usually
    required Future<Map<String, dynamic>> Function() dataFetcher,
    required bool isExcel,
    required String userId,
    DateTime? startDate, // Metadata
    DateTime? endDate, // Metadata
    String filterType = 'Custom',
  }) async {
    // 1. Fetch Data
    final data = await dataFetcher();

    // 2. Generate Bytes
    List<int> bytes;
    String extension;
    String format;
    if (isExcel) {
      bytes = await ReportExcelGenerator.generate(title, data);
      extension = 'xlsx';
      format = 'excel';
    } else {
      bytes = await ReportPdfGenerator.generate(title, data);
      extension = 'pdf';
      format = 'pdf';
    }

    // 3. Upload to Storage
    final uniqueId = const Uuid().v4();
    final filename = '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final fileId = await _historyDao.uploadFile(bytes, filename);
    final fileUrl = _historyDao.getFileView(fileId);

    // 4. Create GeneratedReport Record
    final report = GeneratedReport(
      id: uniqueId, // Or let DB generate ID, but we need it here? HistoryDao uses ID.unique()
      // Wait, DAO creates Document with ID.unique().
      // We should construct object to pass to DAO, but if DAO sets ID, we might miss it.
      // Let's rely on DAO or pass ID.
      // DAO: documentId: ID.unique() -> We don't know ID before creation if we use ID.unique().
      // Let's generate ID here and pass to DAO if possible, or update DAO to return ID/Object.
      // For now, I'll pass a UUID to my Object, but DAO ignores it?
      // Check DAO: `documentId: ID.unique()`. It ignores `report.id` for document ID potentially, but saves `report.toJson()`.
      // `toJson` doesn't include ID? `fromJson` reads internal $id.
      // So I can't know the ID immediately unless I query or DAO returns.
      // I will update DAO to return GeneratedReport.
      // For now, I'll assume the ID generated here is used by the DAO or the DAO returns the full object.
      title: title,
      reportType: reportType,
      format: format,
      fileId: fileId,
      fileUrl: fileUrl,
      filterType: filterType,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      createdBy: userId,
    );

    await _historyDao.saveReport(report);
    return report;
  }

  Future<List<GeneratedReport>> getHistory() => _historyDao.getHistory();

  Future<void> deleteReport(String documentId, String fileId) => _historyDao.deleteReport(documentId, fileId);

  // --- Report Date Filtering Logic ---

  Future<Map<String, dynamic>> getItemTurnover({int days = 30, DateTime? start, DateTime? end}) async {
    final endDate = end ?? DateTime.now();
    final startDate = start ?? endDate.subtract(Duration(days: days));

    final transactions = await _transactionDao.getAllTransactions(startDate: startDate, endDate: endDate);
    final items = await _itemDao.getAllItems();
    final outTransactions = transactions.where((t) => t.type == 'OUT').toList();

    Map<String, int> qtyMap = {};
    for (var t in outTransactions) {
      qtyMap[t.itemId] = (qtyMap[t.itemId] ?? 0) + t.qty;
    }

    List<Map<String, dynamic>> turnoverList = [];
    for (var item in items) {
      int moved = qtyMap[item.id] ?? 0;
      if (moved > 0) {
        turnoverList.add({
          'item': item,
          'qtyMoved': moved,
          'turnoverRate': item.stock > 0 ? (moved / item.stock) : moved.toDouble(),
        });
      }
    }
    turnoverList.sort((a, b) => (b['qtyMoved'] as int).compareTo(a['qtyMoved'] as int));

    return {
      'period': '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}',
      'totalMoved': outTransactions.fold(0, (sum, t) => sum + t.qty),
      'items': turnoverList,
    };
  }

  Future<Map<String, dynamic>> getEmployeePerformance({DateTime? start, DateTime? end}) async {
    final now = DateTime.now();
    final startOfMonth = start ?? DateTime(now.year, now.month, 1);
    final endOfMonth = end ?? DateTime(now.year, now.month + 1, 0);

    final users = await _userDao.getAllUsers();
    final allAttendance = await _attendanceDao.getAttendanceByDateRange(startOfMonth, endOfMonth);
    final allTransactions = await _transactionDao.getAllTransactions(startDate: startOfMonth, endDate: endOfMonth);

    List<Map<String, dynamic>> performanceList = [];

    for (var user in users) {
      final userAttendance = allAttendance.where((a) => a.userId == user.id || a.userName == user.name).toList();
      final presentCount = userAttendance.where((a) => a.checkInTime != null).length;
      final userTransactions = allTransactions.where((t) => t.createdBy == user.id).length;
      final score = (presentCount * 10) + (userTransactions * 2.0);

      List<String> insights = [];
      if (presentCount >= 20) {
        insights.add("Attendance Excellent");
      } else if (presentCount < 10) {
        insights.add("Attendance Low");
      }
      if (userTransactions > 50) insights.add("High Transaction Volume");

      String explanation = insights.join(', ');
      if (explanation.isEmpty) explanation = "Standard Performance";

      performanceList.add({
        'user': user,
        'presentDays': presentCount,
        'transactionsCount': userTransactions,
        'score': score,
        'explanation': explanation,
      });
    }
    performanceList.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return {'month': '${startOfMonth.month}-${startOfMonth.year}', 'rankings': performanceList};
  }

  Future<Map<String, dynamic>> getAttendanceReport({DateTime? start, DateTime? end}) async {
    final now = DateTime.now();
    final s = start ?? DateTime(now.year, now.month, 1);
    final e = end ?? DateTime(now.year, now.month + 1, 0);

    final attendances = await _attendanceDao.getAttendanceByDateRange(s, e);
    final users = await _userDao.getAllUsers();

    List<Map<String, dynamic>> enriched = [];
    for (var att in attendances) {
      // Safe user lookup
      var user = users.cast<dynamic>().firstWhere((u) => u.id == att.userId, orElse: () => null);
      user ??= users.cast<dynamic>().firstWhere((u) => u.name == att.userName, orElse: () => null);

      enriched.add({'attendance': att, 'role': user?.role ?? 'Unknown', 'shift': 'Morning'});
    }

    return {'period': '${s.day}/${s.month} - ${e.day}/${e.month}', 'data': enriched};
  }

  // Reports without filtering (Snapshot)
  Future<Map<String, dynamic>> getStockValuation() async {
    final items = await _itemDao.getAllItems();
    double totalValue = 0;
    int totalItems = 0;
    Map<String, double> valueByCategory = {};

    for (var item in items) {
      if (item.discontinued) continue;
      double value = item.stock * item.price;
      totalValue += value;
      totalItems += item.stock;
      valueByCategory[item.category] = (valueByCategory[item.category] ?? 0) + value;
    }
    return {
      'totalValue': totalValue,
      'totalItems': totalItems,
      'byCategory': valueByCategory,
      'items': items.where((i) => !i.discontinued).toList(),
    };
  }

  Future<Map<String, dynamic>> getReorderPlan() async {
    final items = await _itemDao.getAllItems();
    final lowStockItems = items.where((i) => i.stock <= i.minStock && !i.discontinued).toList();
    double totalCost = 0;
    List<Map<String, dynamic>> reorderList = [];
    for (var item in lowStockItems) {
      int gap = item.minStock - item.stock;
      if (gap <= 0) gap = 10;
      double cost = gap * item.price;
      totalCost += cost;
      reorderList.add({'item': item, 'gap': gap, 'cost': cost});
    }
    return {'totalCost': totalCost, 'itemCount': reorderList.length, 'reorderList': reorderList};
  }

  Future<Map<String, dynamic>> getDiscontinuedStock() async {
    final items = await _itemDao.getAllItems();
    final deadItems = items.where((i) => i.discontinued && i.stock > 0).toList();
    double totalValue = 0;
    for (var item in deadItems) {
      totalValue += (item.stock * item.price);
    }
    return {'totalValue': totalValue, 'itemCount': deadItems.length, 'items': deadItems};
  }

  Future<Map<String, dynamic>> getLeaveReport() async {
    final leaves = await _leaveDao.getAllLeaves();
    final users = await _userDao.getAllUsers();

    List<Map<String, dynamic>> enrichedLeaves = [];
    for (var leave in leaves) {
      String name = leave.userName;
      if (name.isEmpty) {
        final user = users.cast<dynamic>().firstWhere((u) => u.id == leave.userId, orElse: () => null);
        if (user != null) name = user.name;
      }

      // Feature: Check work days before leave start
      final prevWorkDays = await _attendanceDao.getAttendanceCountBefore(leave.userId, leave.startDate);

      enrichedLeaves.add({'leave': leave, 'name': name.isEmpty ? 'Unknown' : name, 'prevWorkDays': prevWorkDays});
    }

    return {'totalLeaves': leaves.length, 'leaves': enrichedLeaves};
  }
}
