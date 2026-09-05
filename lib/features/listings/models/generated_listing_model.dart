class GeneratedListingModel {
  final String title;

  final String description;

  final String benefits;

  final List<String> keywords;

  final double suggestedPrice;

  GeneratedListingModel({
    required this.title,
    required this.description,
    required this.benefits,
    required this.keywords,
    required this.suggestedPrice,
  });

  factory GeneratedListingModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return GeneratedListingModel(
      title:
          json['title'] ?? '',

      description:
          json['description'] ?? '',

      benefits:
          json['benefits'] ?? '',

      keywords:
          List<String>.from(
        json['keywords'] ?? [],
      ),

      suggestedPrice:
          (json['suggestedPrice'] ?? 0)
              .toDouble(),
    );
  }
}