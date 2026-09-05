import '../models/generated_logo_model.dart';

class AILogoService {
  Future<List<GeneratedLogoModel>>
      generateLogos({
    required String brandName,
    required String description,
  }) async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    return [
      GeneratedLogoModel(
        imageUrl:
            'https://via.placeholder.com/300',
        style: 'Minimal',
        prompt: '',
      ),
      GeneratedLogoModel(
        imageUrl:
            'https://via.placeholder.com/300',
        style: 'Premium',
        prompt: '',
      ),
      GeneratedLogoModel(
        imageUrl:
            'https://via.placeholder.com/300',
        style: 'Modern',
        prompt: '',
      ),
      GeneratedLogoModel(
        imageUrl:
            'https://via.placeholder.com/300',
        style: 'Luxury',
        prompt: '',
      ),
    ];
  }
}