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
  });

  factory GeneratedBrandModel.fromJson(Map<String, dynamic> json) {
    return GeneratedBrandModel(
      brandId: json['brandId'],
      brandName: json['brandName'] ?? '',
      tagline: json['tagline'] ?? '',
      description: json['description'] ?? '',
      colors: List<String>.from(json['colors'] ?? []),
      personalityTraits: List<String>.from(json['personalityTraits'] ?? []),
      targetAudience: List<String>.from(json['targetAudience'] ?? []),
      brandScore: json['brandScore'] ?? 0,
      city: (json['city'] ?? '').toString(),
    );
  }
}
