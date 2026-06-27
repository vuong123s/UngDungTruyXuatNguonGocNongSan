class DiseaseCandidate {
  const DiseaseCandidate({
    required this.code,
    required this.name,
    required this.confidence,
    required this.riskLevel,
    required this.description,
    required this.recommendations,
  });

  final String code;
  final String name;
  final double confidence;
  final String riskLevel;
  final String description;
  final List<String> recommendations;

  factory DiseaseCandidate.fromJson(Map<String, dynamic> json) {
    return DiseaseCandidate(
      code: (json['disease_code'] ?? '').toString(),
      name: (json['disease_name'] ?? '').toString(),
      confidence: json['confidence'] is num
          ? (json['confidence'] as num).toDouble()
          : double.tryParse(json['confidence']?.toString() ?? '') ?? 0,
      riskLevel: (json['risk_level'] ?? 'low').toString(),
      description: (json['description'] ?? '').toString(),
      recommendations:
          (json['recommendations'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
    );
  }
}

class DiseaseDetection {
  const DiseaseDetection({
    required this.id,
    required this.productId,
    required this.productName,
    required this.cropName,
    required this.symptoms,
    required this.notes,
    required this.imageUrls,
    required this.candidates,
    required this.topDisease,
    required this.overallRisk,
    required this.modelVersion,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String cropName;
  final List<String> symptoms;
  final String notes;
  final List<String> imageUrls;
  final List<DiseaseCandidate> candidates;
  final DiseaseCandidate topDisease;
  final String overallRisk;
  final String modelVersion;
  final DateTime createdAt;

  factory DiseaseDetection.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap = product is Map<String, dynamic> ? product : null;
    final candidates = (json['candidates'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DiseaseCandidate.fromJson)
        .toList();
    final topRaw = json['top_disease'];
    final topDisease = topRaw is Map<String, dynamic>
        ? DiseaseCandidate.fromJson(topRaw)
        : candidates.isNotEmpty
        ? candidates.first
        : DiseaseCandidate.fromJson(const {
            'disease_code': 'unknown',
            'disease_name': 'Chưa có kết quả',
            'confidence': 0,
            'risk_level': 'low',
            'description': '',
            'recommendations': <String>[],
          });

    return DiseaseDetection(
      id: (json['_id'] ?? '').toString(),
      productId: productMap == null
          ? (product ?? '').toString()
          : (productMap['_id'] ?? '').toString(),
      productName: productMap == null
          ? 'Lô nông sản'
          : (productMap['name'] ?? 'Lô nông sản').toString(),
      cropName: (json['crop_name'] ?? '').toString(),
      symptoms: (json['symptoms'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      notes: (json['notes'] ?? '').toString(),
      imageUrls: (json['images'] as List<dynamic>? ?? const [])
          .map((item) => item is Map ? (item['path'] ?? '').toString() : '')
          .where((item) => item.isNotEmpty)
          .toList(),
      candidates: candidates,
      topDisease: topDisease,
      overallRisk: (json['overall_risk'] ?? topDisease.riskLevel).toString(),
      modelVersion: (json['model_version'] ?? 'ruleset-v1').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
