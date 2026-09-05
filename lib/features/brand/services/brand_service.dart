import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../models/brand_model.dart';
import '../../ai_brand_builder/models/generated_brand_model.dart';
import '../repositories/brand_repository.dart';
import 'brand_storage_service.dart';

class BrandService {
  final BrandStorageService
    storageService =
        BrandStorageService();
        Future<void> saveBrandLogo({
  required String brandId,
  required Uint8List bytes,
}) async {

  final logoUrl =
      await storageService
          .uploadLogo(
    brandId: brandId,
    bytes: bytes,
  );

  await repository.updateLogo(
    brandId: brandId,
    logoUrl: logoUrl,
  );
}
Future<Map<String, dynamic>?> getBrand(
  String brandId,
) async {
  return repository.getBrandById(
    brandId,
  );
}
  final BrandRepository repository =
      BrandRepository();
  Future<void> createBrand(
  BrandModel brand,
) async {
  await repository.saveBrand(
    brandData: {
      'brandId': brand.brandId,
      'sellerId': brand.sellerId,
      'brandName': brand.brandName,
      'description': brand.description,
      'logoUrl': brand.logoUrl,
      'bannerUrl': brand.bannerUrl,
      'city': brand.city,
      'deliveryAvailable':
          brand.deliveryAvailable,
      'rating': brand.rating,
      'totalReviews':
          brand.totalReviews,
      'aiGenerated': false,
      'createdAt':
          DateTime.now()
              .toIso8601String(),
      'updatedAt':
          DateTime.now()
              .toIso8601String(),
    },
  );
}
Future<void> updateBrand({
  required String brandId,
  required String brandName,
  required String tagline,
  required String description,
}) async {
  await repository.updateBrand(
    brandId: brandId,
    data: {
      'brandName': brandName,
      'tagline': tagline,
      'description': description,
      'updatedAt':
          DateTime.now()
              .toIso8601String(),
    },
  );
}
Future<Map<String, dynamic>?> getSellerBrand() async {
  final user =
      FirebaseAuth.instance.currentUser;

  if (user == null) {
    return null;
  }

  return repository.getBrandBySeller(
    user.uid,
  );
}

  Future<String> saveGeneratedBrand(
    GeneratedBrandModel brand,
  ) async {
    final user =
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      throw Exception(
        'User not logged in',
      );
    }

    final brandId =
        const Uuid().v4();

    await repository.saveBrand(
      brandData: {
        'brandId': brandId,
        'sellerId': user.uid,

        'brandName':
            brand.brandName,

        'tagline':
            brand.tagline,

        'description':
            brand.description,

        'colors':
            brand.colors,

        'personalityTraits':
            brand.personalityTraits,

        'targetAudience':
            brand.targetAudience,

        'brandScore':
            brand.brandScore,

        'logoUrl': '',

        'bannerUrl': '',

        'aiGenerated': true,

        'createdAt':
            DateTime.now()
                .toIso8601String(),

        'updatedAt':
            DateTime.now()
                .toIso8601String(),
      },
    );

    return brandId;
  }
}