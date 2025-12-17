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
  final String? note;
  final double? totalDuration;
  final int? overtimeHours;
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
    this.note,
    this.totalDuration,
    this.overtimeHours,
    required this.createdAt,
    this.userName,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    T? getVal<T>(String camel, String snake) {
      if (json.containsKey(camel) && json[camel] != null) return json[camel] as T?;
      if (json.containsKey(snake) && json[snake] != null) return json[snake] as T?;
      return null;
    }

    return Attendance(
      id: json['id'] ?? json['\$id'],
      userId: getVal<String>('userId', 'user_id') ?? '',
      date: json['date'],
      checkInTime: DateTime.tryParse(getVal<String>('checkInTime', 'check_in_time') ?? ''),
      checkOutTime: DateTime.tryParse(getVal<String>('checkOutTime', 'check_out_time') ?? ''),
      checkInMethod: getVal<String>('checkInMethod', 'check_in_method'),
      checkOutMethod: getVal<String>('checkOutMethod', 'check_out_method'),
      lat: (getVal<num>('lat', 'lat'))?.toDouble(),
      lng: (getVal<num>('lng', 'lng'))?.toDouble(),
      isValid:
          (json['isValid'] is bool && json['isValid'] == true) ||
          (json['is_valid'] is bool && json['is_valid'] == true) ||
          (json['isValid'] is int && json['isValid'] == 1) ||
          (json['is_valid'] is int && json['is_valid'] == 1),
      note: getVal<String>('note', 'note'),
      totalDuration: (getVal<num>('totalDuration', 'total_duration'))?.toDouble(),
      overtimeHours: getVal<int>('overtimeHours', 'overtime_hours'),
      createdAt: DateTime.tryParse(getVal<String>('createdAt', 'created_at') ?? '') ?? DateTime.now(),
      userName: getVal<String>('userName', 'user_name'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId, // DB requires 'userId'
      'date': date,
      'checkInTime': checkInTime?.toIso8601String(), // likely camel
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkInMethod': checkInMethod,
      'checkOutMethod': checkOutMethod,
      'lat': lat,
      'lng': lng,
      'isValid': isValid,
      'note': note,
      'totalDuration': totalDuration,
      'overtimeHours': overtimeHours,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
