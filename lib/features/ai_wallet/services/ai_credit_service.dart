import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

/// Server-authoritative paid AI path. Do not debit credits in Flutter.
/// Existing free AI flows remain separate until migration and pricing approval.
class AiCreditService {
  final FirebaseFunctions functions;
  AiCreditService({FirebaseFunctions? functions})
      : functions = functions ?? FirebaseFunctions.instance;

  Future<String> generateText({
    required String feature,
    required String input,
  }) async {
    const supported = {
      'brand_identity',
      'brand_name',
      'brand_tagline',
      'brand_description',
      'color_hex',
    };
    if (!supported.contains(feature)) {
      throw ArgumentError.value(feature, 'feature', 'Unsupported text feature');
    }
    final result = await functions.httpsCallable('generateWithAiCredits').call({
      'feature': feature,
      'input': input,
      'requestId': const Uuid().v4().replaceAll('-', ''),
    });
    return Map<String, dynamic>.from(result.data as Map)['output'] as String;
  }

  Future<Map<String, dynamic>> generateBrand(String businessInfo) async {
    final output = await generateText(feature: 'brand_identity', input: businessInfo);
    return Map<String, dynamic>.from(jsonDecode(output) as Map);
  }

  Future<String> generateLogo({
    required String brandName,
    required String tagline,
    required String description,
    required List<String> colors,
  }) async {
    final result = await functions.httpsCallable('generateWithAiCredits').call({
      'feature': 'logo',
      'input': jsonEncode({
        'brandName': brandName,
        'tagline': tagline,
        'description': description,
        'colors': colors,
      }),
      'requestId': const Uuid().v4().replaceAll('-', ''),
    });
    return Map<String, dynamic>.from(result.data as Map)['output'] as String;
  }
}
