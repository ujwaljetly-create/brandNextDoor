import '../../../core/ai/openai_service.dart';
import '../models/generated_brand_model.dart';

class AIBrandService {
  Future<GeneratedBrandModel>
      generateBrand({
    required String businessInfo,
  }) async {
    await Future.delayed(
      const Duration(
        seconds: 2,
      ),
    );

    final json =
    await OpenAIService()
        .generateBrand(
  businessInfo,
);

return GeneratedBrandModel.fromJson(
  json,
);
  }
}