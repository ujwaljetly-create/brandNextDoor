import '../../ai_wallet/services/ai_credit_service.dart';

class AILogoService {
  Future<String> generateLogo({
    required String brandName,
    required String tagline,
    required String description,
    required List colors,
  }) => AiCreditService().generateLogo(
    brandName: brandName,
    tagline: tagline,
    description: description,
    colors: colors.map((e) => e.toString()).toList(),
  );
}
