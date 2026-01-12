class PayrollConfig {
  final String userId;
  final double baseSalary;
  final double transportAllowance;
  final double mealAllowance;
  final double overtimeRate;
  final double latePenalty; // Per minute
  final double absentPenalty; // Per day
  final String shiftStartTime; // "08:00"

  PayrollConfig({
    required this.userId,
    this.baseSalary = 0,
    this.transportAllowance = 0,
    this.mealAllowance = 0,
    this.overtimeRate = 0,
    this.latePenalty = 0,
    this.absentPenalty = 0,
    this.shiftStartTime = "08:00",
  });

  factory PayrollConfig.fromJson(Map<String, dynamic> json) {
    return PayrollConfig(
      userId: json['userId'] ?? json['user_id'] ?? '',
      baseSalary: (json['baseSalary'] ?? 0).toDouble(),
      transportAllowance: (json['transportAllowance'] ?? 0).toDouble(),
      mealAllowance: (json['mealAllowance'] ?? 0).toDouble(),
      overtimeRate: (json['overtimeRate'] ?? 0).toDouble(),
      latePenalty: (json['latePenalty'] ?? 0).toDouble(),
      absentPenalty: (json['absentPenalty'] ?? 0).toDouble(),
      shiftStartTime: json['shiftStartTime'] ?? '08:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'baseSalary': baseSalary,
      'transportAllowance': transportAllowance,
      'mealAllowance': mealAllowance,
      'overtimeRate': overtimeRate,
      'latePenalty': latePenalty,
      'absentPenalty': absentPenalty,
      'shiftStartTime': shiftStartTime,
    };
  }
}
