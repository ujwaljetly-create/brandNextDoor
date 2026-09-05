class BrandSuggestion {
  final String name;
  final String tagline;
  final String palette;
  final String vibe;

  const BrandSuggestion({
    required this.name,
    required this.tagline,
    required this.palette,
    required this.vibe,
  });
}

class BrandGenerator {
  static List<BrandSuggestion> generate(String productName, String description) {
    final normalized = productName.trim().isEmpty ? 'Local Brand' : productName.trim();
    final productSummary = description.trim().isEmpty ? 'premium local commerce' : description.trim().toLowerCase();

    final vibe = _inferVibe(productSummary);
    final palette = _inferPalette(productSummary);

    return [
      BrandSuggestion(
        name: '${_brandRoot(normalized)} Studio',
        tagline: _tagline(productSummary, 'A polished launch story with neighborhood-first energy.'),
        palette: palette,
        vibe: vibe,
      ),
      BrandSuggestion(
        name: '${_brandRoot(normalized)} House',
        tagline: _tagline(productSummary, 'Warm, modern, and made to become a local favorite.'),
        palette: _rotatePalette(palette),
        vibe: 'Community-led elegance with strong social appeal',
      ),
      BrandSuggestion(
        name: 'Next ${_brandRoot(normalized)}',
        tagline: _tagline(productSummary, 'A sharp, memorable identity built for rapid discovery.'),
        palette: _accentPalette(productSummary),
        vibe: 'Momentum-forward, premium, and instantly recognizable',
      ),
    ];
  }

  static String _brandRoot(String normalized) {
    return normalized.split(' ').first;
  }

  static String _inferVibe(String description) {
    if (description.contains('luxury') || description.contains('premium') || description.contains('gift')) {
      return 'Editorial luxury with a warm, giftable glow';
    }
    if (description.contains('wellness') || description.contains('calm') || description.contains('organic')) {
      return 'Calm, restorative, and naturally elevated';
    }
    if (description.contains('art') || description.contains('design') || description.contains('creative')) {
      return 'Creative, gallery-inspired, and highly distinctive';
    }
    if (description.contains('food') || description.contains('cafe') || description.contains('coffee')) {
      return 'Neighborhood energy with tasty, social-first appeal';
    }
    return 'Premium local commerce with a modern storytelling edge';
  }

  static String _inferPalette(String description) {
    if (description.contains('luxury') || description.contains('premium')) {
      return 'Amber / Rose Quartz / Moonlit Navy';
    }
    if (description.contains('wellness') || description.contains('calm') || description.contains('organic')) {
      return 'Sage / Ocean Blue / Soft Pearl';
    }
    if (description.contains('art') || description.contains('design')) {
      return 'Plum / Electric Blue / Graphite';
    }
    if (description.contains('food') || description.contains('coffee') || description.contains('cafe')) {
      return 'Cocoa / Coral / Golden Hour';
    }
    return 'Purple / Pink / Moonlit Blue';
  }

  static String _rotatePalette(String palette) {
    if (palette.startsWith('Amber')) {
      return 'Rose / Ivory / Espresso';
    }
    if (palette.startsWith('Sage')) {
      return 'Aqua / Lime / Cloud';
    }
    if (palette.startsWith('Plum')) {
      return 'Coral / Lavender / Steel';
    }
    if (palette.startsWith('Cocoa')) {
      return 'Mochi / Tangerine / Cream';
    }
    return 'Ocean Blue / Lilac / Soft Glow';
  }

  static String _accentPalette(String description) {
    if (description.contains('luxury') || description.contains('premium')) {
      return 'Gold / Velvet Purple / Deep Ink';
    }
    if (description.contains('wellness') || description.contains('calm') || description.contains('organic')) {
      return 'Verdant / Teal / Mist';
    }
    return 'Electric Purple / Coral / Graphite';
  }

  static String _tagline(String description, String fallback) {
    if (description.isEmpty) {
      return fallback;
    }
    if (description.length > 80) {
      return '${description.substring(0, 80).trim()}…';
    }
    return description;
  }
}
