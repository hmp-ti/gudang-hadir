class Attendance {
  final String id;
  final String userId;
  final String date; // YYYY-MM-DD
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInMethod; // 'QR' or 'GPS'
  final String? checkOutMethod;
  final double? lat;
  final double? lng;
  final bool isValid;
  final DateTime createdAt;

  // Optional: Join
  final String? userName;

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInMethod,
    this.checkOutMethod,
    this.lat,
    this.lng,
    required this.isValid,
    required this.createdAt,
    this.userName,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      userId: json['user_id'],
      date: json['date'],
      checkInTime: json['check_in_time'] != null ? DateTime.parse(json['check_in_time']) : null,
      checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time']) : null,
      checkInMethod: json['check_in_method'],
      checkOutMethod: json['check_out_method'],
      lat: json['lat'],
      lng: json['lng'],
      isValid: (json['is_valid'] as int) == 1,
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'check_in_method': checkInMethod,
      'check_out_method': checkOutMethod,
      'lat': lat,
      'lng': lng,
      'is_valid': isValid ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
