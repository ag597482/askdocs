class SummaryResponse {
  final String pdf;
  final String type;
  final String summary;
  final String scope;

  SummaryResponse({
    required this.pdf,
    required this.type,
    required this.summary,
    required this.scope,
  });

  factory SummaryResponse.fromJson(Map<String, dynamic> json) {
    return SummaryResponse(
      pdf: json['pdf'] as String,
      type: json['type'] as String,
      summary: json['summary'] as String,
      scope: json['scope'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pdf': pdf,
      'type': type,
      'summary': summary,
      'scope': scope,
    };
  }
}
