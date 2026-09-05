import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'ai_config.dart';


class OpenAIService {
  Future<Map<String, dynamic>> generateBrand(
  String businessInfo,
) async {
  final response = await http.post(
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
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content":
              "You are an expert branding consultant. Return ONLY valid JSON."
        },
        {
          "role": "user",
          "content": """
Generate a business brand.

Return ONLY JSON in this exact format:

{
  "brandName":"",
  "tagline":"",
  "description":"",
  "colors":[],
  "personalityTraits":[],
  "targetAudience":[],
  "brandScore":0
}

Business Description:

$businessInfo
"""
        }
      ],
      "response_format": {
        "type": "json_object"
      }
    }),
  );

  debugPrint(
    "STATUS: ${response.statusCode}",
  );

  debugPrint(
    response.body,
  );

  final data =
      jsonDecode(response.body);

  if (data['error'] != null) {
    throw Exception(
      data['error']['message'],
    );
  }

  final content =
      data['choices'][0]
          ['message']['content'];

  debugPrint(
    "PARSED CONTENT:",
  );

  debugPrint(content);

  return jsonDecode(content);
}
Future<String> generateBrandName(
  String businessDescription,
) async {
  final response = await http.post(
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
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content":
              "Generate only one premium business brand name. Return only the name."
        },
        {
          "role": "user",
          "content":
              businessDescription
        }
      ]
    }),
  );

  final data =
      jsonDecode(response.body);

  if (data['error'] != null) {
    throw Exception(
      data['error']['message'],
    );
  }

  return data['choices'][0]
          ['message']
      ['content']
      .toString()
      .trim();
}
Future<String> generateTagline(
  String businessDescription,
) async {
  final response = await http.post(
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
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content":
              "Generate one professional tagline. Return only the tagline."
        },
        {
          "role": "user",
          "content":
              businessDescription
        }
      ]
    }),
  );

  final data =
      jsonDecode(response.body);

  if (data['error'] != null) {
    throw Exception(
      data['error']['message'],
    );
  }

  return data['choices'][0]
          ['message']
      ['content']
      .toString()
      .trim();
}
Future<String> generateDescription(
  String businessDescription,
) async {
  final response = await http.post(
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
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content":
              "Generate a professional business description."
        },
        {
          "role": "user",
          "content":
              businessDescription
        }
      ]
    }),
  );

  final data =
      jsonDecode(response.body);

  if (data['error'] != null) {
    throw Exception(
      data['error']['message'],
    );
  }

  return data['choices'][0]
          ['message']
      ['content']
      .toString()
      .trim();
}
}