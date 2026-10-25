import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ai_wallet/services/ai_credit_service.dart';
import '../../../models/listing_model.dart';

class MarketTipsResult {
  final List<String> tips;
  final bool hasDirectCompetitors;
  const MarketTipsResult({required this.tips, required this.hasDirectCompetitors});
}

class MarketTipsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MarketTipsResult> generate({
    required String sellerId,
    required Map<String, dynamic> brand,
    required List<ListingModel> ownListings,
  }) async {
    final category = (brand['category'] ?? '').toString().trim().toLowerCase();
    final city = (brand['city'] ?? '').toString().trim().toLowerCase();

    final snapshot = await _firestore.collection('listings').where('status', isEqualTo: 'active').limit(80).get();
    final ownCategories = ownListings.map((e) => e.category.toLowerCase()).where((e) => e.isNotEmpty).toSet();
    final candidates = snapshot.docs
        .map((doc) => ListingModel.fromMap(doc.data()))
        .where((item) => item.sellerId != sellerId)
        .where((item) {
          final itemCategory = item.category.toLowerCase();
          final sameCategory = category.isNotEmpty && (itemCategory.contains(category) || category.contains(itemCategory));
          return sameCategory || ownCategories.contains(itemCategory);
        }).toList()
      ..sort((a, b) => b.soldCount.compareTo(a.soldCount));

    final competitors = candidates.take(8).toList();
    final hasDirect = competitors.isNotEmpty;
    final competitorData = <Map<String, dynamic>>[];

    for (final item in competitors) {
      int followers = 0;
      try {
        final count = await _firestore.collection('brands').doc(item.brandId).collection('followers').count().get();
        followers = count.count ?? 0;
      } catch (_) {}
      competitorData.add({
        'title': item.title, 'category': item.category, 'price': item.price,
        'dealPrice': item.hasActiveDeal ? item.dealPrice : null, 'city': item.city,
        'soldCount': item.soldCount, 'rating': item.rating, 'reviews': item.reviewCount,
        'delivery': item.deliveryAvailable, 'pickup': item.pickupAvailable,
        'followers': followers, 'description': item.description,
      });
    }

    final ownData = ownListings.take(12).map((item) => {
      'title': item.title, 'category': item.category, 'price': item.price,
      'dealPrice': item.hasActiveDeal ? item.dealPrice : null, 'city': item.city,
      'soldCount': item.soldCount, 'rating': item.rating,
      'delivery': item.deliveryAvailable, 'pickup': item.pickupAvailable,
      'description': item.description,
    }).toList();

    final prompt = '''
You are a marketplace growth analyst for a local seller.
Generate 3 concise, practical market tips. Do not invent facts.
Compare pricing, promotions, location, followers, product variety, descriptions,
ratings, delivery/pickup options and sales signals when competitor data exists.

Seller brand:
${jsonEncode({'name': brand['brandName'], 'description': brand['description'], 'category': brand['category'], 'city': brand['city'], 'tagline': brand['tagline']})}

Seller products:
${jsonEncode(ownData)}

Similar marketplace products:
${jsonEncode(competitorData)}

Market area: $city
Direct competitor data available: $hasDirect

Return ONLY JSON:
{"tips":["tip 1","tip 2","tip 3"]}
''';

    final responseText = await AiCreditService().generateText(
      feature: 'market_tips',
      input: prompt.length > 11500 ? prompt.substring(0, 11500) : prompt,
    );
    final parsed = jsonDecode(responseText) as Map<String, dynamic>;
    final tips = List<String>.from(parsed['tips'] ?? const <String>[]).where((tip) => tip.trim().isNotEmpty).take(3).toList();

    return MarketTipsResult(
      tips: tips.isEmpty
          ? const ['Keep your product details, pricing and fulfillment options current so buyers can compare your store confidently.']
          : tips,
      hasDirectCompetitors: hasDirect,
    );
  }
}
