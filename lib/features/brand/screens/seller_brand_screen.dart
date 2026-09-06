import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ai_brand_builder/models/generated_brand_model.dart';
import '../services/brand_service.dart';

class SellerBrandScreen extends StatefulWidget {
  const SellerBrandScreen({super.key});

  @override
  State<SellerBrandScreen> createState() => _SellerBrandScreenState();
}

class _SellerBrandScreenState extends State<SellerBrandScreen> {
  bool isLoading = true;
  Map<String, dynamic>? brand;

  @override
  void initState() {
    super.initState();
    loadBrand();
  }

  Future<void> loadBrand() async {
    try {
      final result = await BrandService().getSellerBrand();

      if (!mounted) return;

      setState(() {
        brand = result;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/seller-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (brand == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _goBack,
          ),
          title: const Text('My Brand'),
        ),
        body: const Center(child: Text('No Brand Found')),
      );
    }

    final colors = ((brand!['colors'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final personality = ((brand!['personalityTraits'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final logoUrl = (brand!['logoUrl'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _goBack,
        ),
        title: const Text('My Brand'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7B61FF),
                    Color(0xFFE14DAD),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B61FF)
                        .withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 172,
                    height: 172,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: logoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.storefront,
                                size: 64,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.storefront,
                            size: 64,
                            color: Color(0xFF7B61FF),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    brand!['brandName'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    brand!['tagline'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionCard(
              icon: Icons.description_outlined,
              title: 'Description',
              child: Text(
                brand!['description'] ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.55,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.palette_outlined,
              title: 'Brand Colors',
              child: colors.isEmpty
                  ? const Text('No brand colors added yet.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors
                          .map(
                            (color) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF7B61FF)
                                        .withValues(alpha: 0.10),
                                    const Color(0xFFE14DAD)
                                        .withValues(alpha: 0.10),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFF7B61FF)
                                      .withValues(alpha: 0.28),
                                ),
                              ),
                              child: Text(
                                color,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4C3FB4),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.auto_awesome_outlined,
              title: 'Personality',
              child: personality.isEmpty
                  ? const Text('No personality traits added yet.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: personality
                          .map(
                            (trait) => Chip(
                              avatar: const Icon(
                                Icons.star_outline,
                                size: 17,
                                color: Color(0xFFE14DAD),
                              ),
                              label: Text(trait),
                              backgroundColor: const Color(0xFFF8F2FF),
                              side: BorderSide(
                                color: const Color(0xFFE14DAD)
                                    .withValues(alpha: 0.24),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7B61FF),
                            Color(0xFFE14DAD),
                          ],
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('/create-listing');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Listing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await context.push(
                          '/edit-brand',
                          extra: brand,
                        );

                        if (result == true) {
                          loadBrand();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Brand'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final generatedBrand = GeneratedBrandModel(
                          brandId: brand!['brandId'] ?? '',
                          brandName: brand!['brandName'] ?? '',
                          tagline: brand!['tagline'] ?? '',
                          description: brand!['description'] ?? '',
                          colors: List<String>.from(brand!['colors'] ?? []),
                          personalityTraits: List<String>.from(
                            brand!['personalityTraits'] ?? [],
                          ),
                          targetAudience: List<String>.from(
                            brand!['targetAudience'] ?? [],
                          ),
                          brandScore: brand!['brandScore'] ?? 90,
                        );

                        context.push(
                          '/ai-logo-generation',
                          extra: generatedBrand,
                        );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate AI Logo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF7B61FF).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7B61FF),
                      Color(0xFFE14DAD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
