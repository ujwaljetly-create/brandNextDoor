import 'dart:convert';

import '../../ai_wallet/services/ai_credit_service.dart';
import '../models/generated_listing_model.dart';

class AIListingService {
  Future<GeneratedListingModel> generateListing(String description) async {
    final output = await AiCreditService().generateText(
      feature: 'listing',
      input: description,
    );
    return GeneratedListingModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(output) as Map),
    );
  }
}
