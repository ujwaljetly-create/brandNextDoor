import 'package:cloud_firestore/cloud_firestore.dart';

class BrandRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> saveBrand({
    required Map<String, dynamic> brandData,
  }) async {
    await _firestore
        .collection('brands')
        .doc(brandData['brandId'])
        .set(
          brandData,
          SetOptions(
            merge: true,
          ),
        );
  }
  Future<void> updateBrand({
  required String brandId,
  required Map<String, dynamic> data,
}) async {
  await _firestore
      .collection('brands')
      .doc(brandId)
      .update(data);
}
Future<void> updateLogo({
  required String brandId,
  required String logoUrl,
}) async {
  await _firestore
      .collection('brands')
      .doc(brandId)
      .update({
    'logoUrl': logoUrl,
  });
}
Future<Map<String, dynamic>?> getBrandById(
  String brandId,
) async {
  final doc =
      await _firestore
          .collection('brands')
          .doc(brandId)
          .get();

  if (!doc.exists) {
    return null;
  }

  return doc.data();
}
Future<Map<String, dynamic>?> getBrandBySeller(
  String sellerId,
) async {
  final snapshot =
      await _firestore
          .collection('brands')
          .where(
            'sellerId',
            isEqualTo: sellerId,
          )
          .limit(1)
          .get();

  if (snapshot.docs.isEmpty) {
    return null;
  }

  return snapshot.docs.first.data();
}
  Future<DocumentSnapshot>
      getBrand(
    String brandId,
  ) {
    return _firestore
        .collection('brands')
        .doc(brandId)
        .get();
  }
}