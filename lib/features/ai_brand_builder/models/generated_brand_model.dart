class GeneratedBrandModel {
  final String brandName;
  final String tagline;
  final String description;
  final List<String> colors;
  final List<String> personalityTraits;
  final List<String> targetAudience;
  final int brandScore;
  final String? brandId;
  final String city;
  final String category;

  GeneratedBrandModel({
    this.brandId,
    required this.brandName,
    required this.tagline,
    required this.description,
    required this.colors,
    required this.personalityTraits,
    required this.targetAudience,
    required this.brandScore,
    this.city = '',
    this.category = '',
  });

  factory GeneratedBrandModel.fromJson(Map<String, dynamic> json) {
    return GeneratedBrandModel(
      brandId: json['brandId']?.toString(),
      brandName: (json['brandName'] ?? '').toString(),
      tagline: (json['tagline'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      colors: List<String>.from(json['colors'] ?? const []),
      personalityTraits: List<String>.from(json['personalityTraits'] ?? const []),
      targetAudience: List<String>.from(json['targetAudience'] ?? const []),
      brandScore: (json['brandScore'] as num?)?.toInt() ?? 0,
      city: (json['city'] ?? '').toString(),
      category: (json['category'] ?? json['businessType'] ?? '').toString(),
    );
  }
}
