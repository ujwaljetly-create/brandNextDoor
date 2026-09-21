class GeneratedListingModel {
  final String title;
  final String description;
  final String benefits;
  final List<String> keywords;
  final double suggestedPrice;
  final String category;

  GeneratedListingModel({
    required this.title,
    required this.description,
    required this.benefits,
    required this.keywords,
    required this.suggestedPrice,
    this.category = '',
  });

  factory GeneratedListingModel.fromJson(Map<String, dynamic> json) {
    return GeneratedListingModel(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      benefits: (json['benefits'] ?? '').toString(),
      keywords: List<String>.from(json['keywords'] ?? const []),
      suggestedPrice: (json['suggestedPrice'] as num?)?.toDouble() ?? 0,
      category: (json['category'] ?? '').toString(),
    );
  }

  GeneratedListingModel copyWith({String? category}) => GeneratedListingModel(
        title: title,
        description: description,
        benefits: benefits,
        keywords: keywords,
        suggestedPrice: suggestedPrice,
        category: category ?? this.category,
      );
}
