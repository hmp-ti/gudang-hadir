import 'dart:convert';

class Payroll {
  final String id;
  final String userId;
  final String periodStart; // YYYY-MM-DD
  final String periodEnd; // YYYY-MM-DD
  final double baseSalary;
  final double totalAllowance;
  final double totalOvertime;
  final double totalDeduction;
  final double netSalary;
  final Map<String, dynamic> detail; // JSON breakdown
  final String status; // 'draft', 'paid'
  final DateTime createdAt;

  Payroll({
    required this.id,
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.baseSalary,
    required this.totalAllowance,
    required this.totalOvertime,
    required this.totalDeduction,
    required this.netSalary,
    required this.detail,
    required this.status,
    required this.createdAt,
  });

  factory Payroll.fromJson(Map<String, dynamic> json) {
    var detailData = json['detail'];
    if (detailData is String) {
      try {
        detailData = jsonDecode(detailData);
      } catch (_) {
        detailData = {};
      }
    }

    return Payroll(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      periodStart: json['periodStart'] ?? '',
      periodEnd: json['periodEnd'] ?? '',
      baseSalary: (json['baseSalary'] ?? 0).toDouble(),
      totalAllowance: (json['totalAllowance'] ?? 0).toDouble(),
      totalOvertime: (json['totalOvertime'] ?? 0).toDouble(),
      totalDeduction: (json['totalDeduction'] ?? 0).toDouble(),
      netSalary: (json['netSalary'] ?? 0).toDouble(),
      detail: Map<String, dynamic>.from(detailData ?? {}),
      status: json['status'] ?? 'draft',
      createdAt: DateTime.tryParse(json['\$createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'baseSalary': baseSalary,
      'totalAllowance': totalAllowance,
      'totalOvertime': totalOvertime,
      'totalDeduction': totalDeduction,
      'netSalary': netSalary,
      'detail': detail, // Ensure DB supports JSON/String conversion if needed
      'status': status,
      // 'createdAt': createdAt.toIso8601String(), // Managed by Appwrite
    };
  }
}
