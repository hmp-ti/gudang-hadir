import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../attendance/data/attendance_dao.dart';
import '../../attendance/domain/attendance.dart';
import '../data/payroll_repository.dart';
import 'payroll.dart';
import 'payroll_config.dart';
import '../../../core/services/appwrite_service.dart';

final payrollServiceProvider = Provider(
  (ref) => PayrollService(ref.read(payrollRepositoryProvider), ref.read(attendanceDaoProvider)),
);

final payrollRepositoryProvider = Provider((ref) {
  return PayrollRepository(AppwriteService.instance);
});

class PayrollService {
  final PayrollRepository _payrollRepo;
  final AttendanceDao _attendanceDao;

  PayrollService(this._payrollRepo, this._attendanceDao);

  Future<Payroll> generatePayrollPreview({required String userId, required int month, required int year}) async {
    // 1. Get Config
    final config = await _payrollRepo.getPayrollConfig(userId);

    // 2. Determine Period
    final startDate = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0); // Last day of month
    final endDate = lastDay;

    // 3. Get Attendance
    final attendances = await _attendanceDao.getAttendanceByDateRange(startDate, endDate);

    // 4. Calculate Stats
    int daysPresent = 0;
    int totalLateMinutes = 0;
    double totalOvertimeHours = 0;

    // Shift Start Time Parsing
    final shiftParts = config.shiftStartTime.split(':');
    final shiftHour = int.parse(shiftParts[0]);
    final shiftMinute = int.parse(shiftParts[1]);

    for (var att in attendances) {
      if (!att.isValid) continue; // Skip invalid if necessary, or count them? Assuming valid only.
      daysPresent++;

      if (att.overtimeHours != null) {
        totalOvertimeHours += att.overtimeHours!;
      }

      // Calculate Late
      if (att.checkInTime != null) {
        // We need to compare time part only
        final checkIn = att.checkInTime!;
        final shiftTime = DateTime(checkIn.year, checkIn.month, checkIn.day, shiftHour, shiftMinute);

        if (checkIn.isAfter(shiftTime)) {
          final diff = checkIn.difference(shiftTime);
          totalLateMinutes += diff.inMinutes;
        }
      }
    }

    // 5. Calculate Absent Days
    // Logic: Count Mon-Sat (or Mon-Fri?) as workings days.
    // Let's assume Mon-Sat (6 days) is standard in ID.
    int workingDaysInMonth = 0;
    for (int i = 0; i < lastDay.day; i++) {
      final day = startDate.add(Duration(days: i));
      if (day.weekday != DateTime.sunday) {
        // Assume Sunday is off
        workingDaysInMonth++;
      }
    }
    int absentDays = 0;
    if (workingDaysInMonth > daysPresent) {
      absentDays = workingDaysInMonth - daysPresent;
    }

    // 6. Monetary Calculations
    final baseSalary = config.baseSalary;
    final transportMoney = config.transportAllowance * daysPresent;
    final mealMoney = config.mealAllowance * daysPresent;
    final overtimeMoney = config.overtimeRate * totalOvertimeHours;

    final totalAllowance = transportMoney + mealMoney;

    final lateDeduction = config.latePenalty * totalLateMinutes;
    final absentDeduction = config.absentPenalty * absentDays;

    final totalDeduction = lateDeduction + absentDeduction;

    final netSalary = (baseSalary + totalAllowance + overtimeMoney) - totalDeduction;

    // 7. Create Object
    return Payroll(
      id: '', // Draft
      userId: userId,
      periodStart: DateFormat('yyyy-MM-dd').format(startDate),
      periodEnd: DateFormat('yyyy-MM-dd').format(endDate),
      baseSalary: baseSalary,
      totalAllowance: totalAllowance,
      totalOvertime: overtimeMoney,
      totalDeduction: totalDeduction,
      netSalary: netSalary,
      status: 'draft',
      createdAt: DateTime.now(),
      detail: {
        'daysPresent': daysPresent,
        'workingDays': workingDaysInMonth,
        'absentDays': absentDays,
        'totalLateMinutes': totalLateMinutes,
        'totalOvertimeHours': totalOvertimeHours,
        'breakdown': {
          'transport': transportMoney,
          'meal': mealMoney,
          'totalOvertime': overtimeMoney,
          'lateDeduction': lateDeduction,
          'absentDeduction': absentDeduction,
        },
      },
    );
  }
}
