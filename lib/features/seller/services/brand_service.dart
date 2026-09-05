import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/brand_model.dart';

class BrandService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> createBrand(
    BrandModel brand,
  ) async {
    await firestore
        .collection('brands')
        .doc(brand.brandId)
        .set(
          brand.toMap(),
        );
  }

  Future<BrandModel?> getBrand(
    String brandId,
  ) async {
    final doc = await firestore
        .collection('brands')
        .doc(brandId)
        .get();

    if (!doc.exists) return null;

    return BrandModel.fromMap(
      doc.data()!,
    );
  }
}