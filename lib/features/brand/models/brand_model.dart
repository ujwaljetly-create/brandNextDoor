class BrandModel {
  final String brandId;
  final String sellerId;

  final String brandName;
  final String description;

  final String logoUrl;
  final String bannerUrl;

  final String city;

  final bool deliveryAvailable;

  final double rating;

  final int totalReviews;

  BrandModel({
    required this.brandId,
    required this.sellerId,
    required this.brandName,
    required this.description,
    required this.logoUrl,
    required this.bannerUrl,
    required this.city,
    required this.deliveryAvailable,
    required this.rating,
    required this.totalReviews,
  });

  factory BrandModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return BrandModel(
      brandId: map['brandId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      brandName: map['brandName'] ?? '',
      description:
          map['description'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      bannerUrl:
          map['bannerUrl'] ?? '',
      city: map['city'] ?? '',
      deliveryAvailable:
          map['deliveryAvailable'] ??
              false,
      rating:
          (map['rating'] ?? 0)
              .toDouble(),
      totalReviews:
          map['totalReviews'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brandId': brandId,
      'sellerId': sellerId,
      'brandName': brandName,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'city': city,
      'deliveryAvailable':
          deliveryAvailable,
      'rating': rating,
      'totalReviews':
          totalReviews,
    };
  }
}