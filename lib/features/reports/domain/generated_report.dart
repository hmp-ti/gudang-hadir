class GeneratedReport {
  final String id;
  final String title;
  final String reportType;
  final String format; // pdf or xlsx
  final String fileId;
  final String fileUrl;
  final String filterType;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final String createdBy;

  GeneratedReport({
    required this.id,
    required this.title,
    required this.reportType,
    required this.format,
    required this.fileId,
    required this.fileUrl,
    required this.filterType,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.createdBy,
  });

  factory GeneratedReport.fromJson(Map<String, dynamic> json) {
    String type = json['reportType'] ?? '';
    String fmt = 'pdf';
    if (type.endsWith('_excel')) {
      fmt = 'excel';
      type = type.replaceAll('_excel', '');
    } else if (type.endsWith('_pdf')) {
      fmt = 'pdf';
      type = type.replaceAll('_pdf', '');
    } else {
      // Fallback: check outdated 'format' field if exists (optional)
      if (json['format'] != null) fmt = json['format'];
    }

    return GeneratedReport(
      id: json['\$id'] ?? '',
      title: json['title'] ?? '',
      reportType: type,
      format: fmt,
      fileId: json['fileId'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      filterType: json['filterType'] ?? 'One-Time',
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      createdAt: DateTime.tryParse(json['\$createdAt']) ?? DateTime.now(),
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'reportType': '${reportType}_$format', // Merge format into reportType to avoid schema error
      // 'format': format, // Removed to fix "Unknown attribute" error
      'fileId': fileId,
      'fileUrl': fileUrl,
      'filterType': filterType,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}
