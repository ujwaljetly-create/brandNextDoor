import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/brand_generator.dart';

class BrandConceptService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveConcept(BrandSuggestion suggestion) async {
    await _firestore.collection('brand_concepts').add({
      'name': suggestion.name,
      'tagline': suggestion.tagline,
      'palette': suggestion.palette,
      'vibe': suggestion.vibe,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<BrandSuggestion>> loadSavedConcepts() async {
    final snapshot = await _firestore
        .collection('brand_concepts')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BrandSuggestion(
        name: data['name'] as String,
        tagline: data['tagline'] as String,
        palette: data['palette'] as String,
        vibe: data['vibe'] as String,
      );
    }).toList();
  }
}
