import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/ai/ai_config.dart';

class AILogoService {
  Future<String> generateLogo({
    required String brandName,
    required String tagline,
    required String description,
    required List colors,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/images/generations'),
      headers: {
        'Authorization': 'Bearer ${AIConfig.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-image-1',
        'size': '1024x1024',
        'background': 'transparent',
        'prompt': '''
Create a premium modern business logo.

Brand Name: $brandName
Tagline: $tagline
Business Description: $description
Brand Colors: ${colors.join(', ')}

Requirements:
- Transparent background
- Premium local-business style
- Modern, professional typography
- Clean vector-like composition
- Suitable for a mobile storefront and website
''',
      }),
    );

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Logo service returned an invalid response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final apiError = data['error'];
      final message = apiError is Map
          ? (apiError['message'] ?? 'Logo generation failed').toString()
          : 'Logo generation failed';
      throw Exception(message);
    }

    final items = data['data'];
    if (items is! List || items.isEmpty || items.first is! Map) {
      throw Exception('No logo was returned. Please try again.');
    }

    final encoded = (items.first as Map)['b64_json'];
    if (encoded is! String || encoded.isEmpty) {
      throw Exception('The generated logo could not be read. Please try again.');
    }
    return encoded;
  }
}
