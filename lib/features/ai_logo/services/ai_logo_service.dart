import 'dart:convert';

import 'package:flutter/foundation.dart';
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
      Uri.parse(
        'https://api.openai.com/v1/images/generations',
      ),
      headers: {
        'Authorization':
            'Bearer ${AIConfig.apiKey}',
        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        "model": "gpt-image-1",
        "size": "1024x1024",
        "background": "transparent",
        "prompt": """
Create a premium modern business logo.

Brand Name:
$brandName

Tagline:
$tagline

Business Description:
$description

Brand Colors:
${colors.join(', ')}

Requirements:
- Transparent background
- Premium startup style
- Modern logo
- Professional typography
- Clean vector style
- Suitable for mobile app and website
- High quality branding
""",
      }),
    );

    debugPrint(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        'Logo generation failed: ${response.body}',
      );
    }

    final data =
        jsonDecode(response.body);

    if (data['data'] == null ||
        data['data'].isEmpty) {
      throw Exception(
        'No logo returned from OpenAI',
      );
    }

    return data['data'][0]
        ['b64_json'];
  }
}