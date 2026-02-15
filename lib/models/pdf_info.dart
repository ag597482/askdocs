class PDFInfo {
  final String name;
  final String uploadedBy;
  final int totalPages;
  final List<String> chapters;
  final DateTime uploadDate;

  PDFInfo({
    required this.name,
    required this.uploadedBy,
    required this.totalPages,
    required this.chapters,
    required this.uploadDate,
  });

  factory PDFInfo.fromJson(Map<String, dynamic> json) {
    return PDFInfo(
      name: json['name'] as String,
      uploadedBy: json['uploaded_by'] as String,
      totalPages: json['total_pages'] as int,
      chapters: List<String>.from(json['chapters'] as List),
      uploadDate: DateTime.parse(json['upload_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uploaded_by': uploadedBy,
      'total_pages': totalPages,
      'chapters': chapters,
      'upload_date': uploadDate.toIso8601String(),
    };
  }
}
