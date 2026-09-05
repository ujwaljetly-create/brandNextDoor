import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIConfig {
  static String get apiKey =>
      dotenv.env['OPENAI_API_KEY'] ?? '';
}