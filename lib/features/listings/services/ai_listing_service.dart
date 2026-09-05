import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/ai/ai_config.dart';
import '../models/generated_listing_model.dart';

class AIListingService {

  Future<GeneratedListingModel>
      generateListing(
    String productDescription,
  ) async {

    final response =
        await http.post(
      Uri.parse(
        'https://api.openai.com/v1/chat/completions',
      ),
      headers: {
        'Authorization':
            'Bearer ${AIConfig.apiKey}',
        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        "model": "gpt-5",
        "response_format": {
          "type": "json_object"
        },
        "messages": [
          {
            "role": "system",
            "content":
                """
Generate product listing JSON.

Return:

{
"title":"",
"description":"",
"benefits":"",
"keywords":[],
"suggestedPrice":0
}

Return valid JSON only.
"""
          },
          {
            "role": "user",
            "content":
                productDescription
          }
        ]
      }),
    );

    final data =
        jsonDecode(
      response.body,
    );

    final content =
        data['choices'][0]
            ['message']
                ['content'];

    return GeneratedListingModel
        .fromJson(
      jsonDecode(
        content,
      ),
    );
  }
}