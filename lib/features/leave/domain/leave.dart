class Leave {
  final String id;
  final String userId;
  final String userName;
  final String reason;
  final String startDate;
  final String endDate;
  final String status;
  final String? adminId;
  final String? pdfFileId;
  final DateTime createdAt;

  Leave({
    required this.id,
    required this.userId,
    required this.userName,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.adminId,
    this.pdfFileId,
    required this.createdAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      reason: json['reason'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? 'pending',
      adminId: json['adminId'],
      pdfFileId: json['pdfFileId'],
      createdAt: DateTime.tryParse(json['\$createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'reason': reason,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'adminId': adminId,
      'pdfFileId': pdfFileId,
    };
  }
}
