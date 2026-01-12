import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../warehouse/data/item_dao.dart';
import '../../attendance/data/attendance_dao.dart';

final smartAssistantServiceProvider = Provider((ref) {
  return SmartAssistantService(ref.read(itemDaoProvider), ref.read(attendanceDaoProvider));
});

class SmartAssistantService {
  final ItemDao _itemDao;
  final AttendanceDao _attendanceDao;
  final Gemini _gemini = Gemini.instance;

  SmartAssistantService(this._itemDao, this._attendanceDao);

  Future<Stream<Candidates>> chat(String message) async {
    return _gemini.promptStream(parts: [Part.text(message)]).map((e) => e!);
  }

  Future<Stream<Candidates>> analyzeInventory(String specificQuery) async {
    // 1. Fetch relevant data
    final items = await _itemDao.getAllItems();
    final lowStock = items.where((i) => i.stock <= i.minStock).toList();
    final zeroStock = items.where((i) => i.stock == 0).toList();

    // 2. Construct Prompt
    final promptBuffer = StringBuffer();
    promptBuffer.writeln("Act as an expert Supply Chain Manager.");
    promptBuffer.writeln("Analyze the following inventory status and provide actionable decisions.");
    promptBuffer.writeln("IMPORTANT: Provide the response in Bahasa Indonesia.");
    promptBuffer.writeln("Context:");
    promptBuffer.writeln("- Total Items: ${items.length}");
    promptBuffer.writeln("- Items Out of Stock: ${zeroStock.length}");
    promptBuffer.writeln("- Items Low Stock: ${lowStock.length}");

    if (lowStock.isNotEmpty) {
      promptBuffer.writeln("Low Stock Items details: ");
      for (var item in lowStock.take(10)) {
        // Limit to 10 to check token limits
        promptBuffer.writeln("- ${item.name}: Stock ${item.stock} (Min ${item.minStock})");
      }
      if (lowStock.length > 10) promptBuffer.writeln("...and ${lowStock.length - 10} more.");
    }

    if (specificQuery.isNotEmpty) {
      promptBuffer.writeln("\nSpecific User Question: $specificQuery");
    } else {
      promptBuffer.writeln(
        "\ngoal: Provide a summary of critical issues and 3 specific recommendations to optimize stock.",
      );
    }

    return _gemini.promptStream(parts: [Part.text(promptBuffer.toString())]).map((e) => e!);
  }

  Future<Stream<Candidates>> analyzeHR(String specificQuery) async {
    // 1. Fetch relevant data (Last 30 days)
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final history = await _attendanceDao.getAttendanceByDateRange(startDate, now);

    // Group by User
    final Map<String, int> lateCounts = {};
    final Map<String, int> absentCounts =
        {}; // We assume we can calculate absent from schedule, but here we count presents

    // Simple analysis: Late count (if checkIn > 08:00? We don't have schedule here easily.
    // We'll rely on what data we have. Attendance object has checkInTime.)
    // Let's assume 8:00 AM is standard for this generic analysis or just list statistics.

    for (var att in history) {
      if (att.checkInTime != null) {
        // Check if late (simple check > 8:15)
        if (att.checkInTime!.hour > 8 || (att.checkInTime!.hour == 8 && att.checkInTime!.minute > 15)) {
          final name = att.userName ?? att.userId;
          lateCounts[name] = (lateCounts[name] ?? 0) + 1;
        }
      }
    }

    // 2. Construct Prompt
    final promptBuffer = StringBuffer();
    promptBuffer.writeln("Act as an expert HR Manager.");
    promptBuffer.writeln("Analyze the following attendance data (Last 30 days) and suggest solutions.");
    promptBuffer.writeln("Use bahasa Indonesia suitable for a formal report.");

    if (lateCounts.isNotEmpty) {
      promptBuffer.writeln("List of Late Employees (More than 15 mins late):");
      lateCounts.forEach((name, count) {
        promptBuffer.writeln("- $name: Late $count times");
      });
    } else {
      promptBuffer.writeln("No significant lateness recorded.");
    }

    if (specificQuery.isNotEmpty) {
      promptBuffer.writeln("\nSpecific Manager Question: $specificQuery");
    } else {
      promptBuffer.writeln("\nGoal: Analyze trends and suggest how to improve discipline or engagement.");
    }

    return _gemini.promptStream(parts: [Part.text(promptBuffer.toString())]).map((e) => e!);
  }
}
