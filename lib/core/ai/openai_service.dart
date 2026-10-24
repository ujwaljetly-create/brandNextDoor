import 'dart:convert';
import '../../features/ai_wallet/services/ai_credit_service.dart';

class OpenAIService {
  final AiCreditService _ai = AiCreditService();

  Future<Map<String, dynamic>> generateBrand(String businessInfo) =>
      _ai.generateBrand(businessInfo);

  Future<String> generateBrandName(String description) =>
      _ai.generateText(feature: 'brand_name', input: description);

  Future<String> generateTagline(String description) =>
      _ai.generateText(feature: 'brand_tagline', input: description);

  Future<String> generateDescription(String description) =>
      _ai.generateText(feature: 'brand_description', input: description);

  Future<String> resolveColorHex(String name) async {
    final text = await _ai.generateText(feature: 'color_hex', input: name);
    final hex = (jsonDecode(text) as Map<String, dynamic>)['hex'].toString().toUpperCase();
    if (!RegExp(r'^#[0-9A-F]{6}$').hasMatch(hex)) {
      throw const FormatException('Invalid color returned by AI');
    }
    return hex;
  }
}
