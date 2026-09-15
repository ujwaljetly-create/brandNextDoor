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
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

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
      setState(() => isLoading = false);
    }
  }

  void _goBack() => context.canPop() ? context.pop() : context.go('/seller-dashboard');

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _gold)));
    }
    if (brand == null) {
      return Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(backgroundColor: _cream, leading: IconButton(icon: const Icon(Icons.arrow_back, color: _navy), onPressed: _goBack), title: const Text('Preview Store')),
        body: const Center(child: Text('No Brand Found')),
      );
    }

    final logoUrl = (brand!['logoUrl'] ?? '').toString();
    final colors = ((brand!['colors'] as List?) ?? []).map((e) => e.toString()).toList();
    final personality = ((brand!['personalityTraits'] as List?) ?? []).map((e) => e.toString()).toList();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _navy), onPressed: _goBack),
        title: const Text('Preview Store', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFFD3AD78), Color(0xFFF0DDC3)]),
            ),
            child: Center(
              child: Container(
                width: 130,
                height: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5D6BF), width: 3)),
                child: logoUrl.isNotEmpty
                    ? ClipOval(child: Image.network(logoUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: _navy, size: 54)))
                    : const Icon(Icons.storefront, color: _navy, size: 54),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  (brand!['brandName'] ?? '').toString(),
                  style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 30, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE3F3EB), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified, color: Color(0xFF2A8F6A), size: 16), SizedBox(width: 5), Text('Local Brand', style: TextStyle(color: Color(0xFF2A8F6A), fontSize: 11, fontWeight: FontWeight.w700))]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text((brand!['tagline'] ?? '').toString(), style: const TextStyle(color: Color(0xFF58666D), fontSize: 15)),
          const SizedBox(height: 18),
          Text((brand!['description'] ?? '').toString(), style: const TextStyle(color: _navy, fontSize: 15, height: 1.55)),
          const SizedBox(height: 24),
          _section('Brand Colors', Wrap(spacing: 8, runSpacing: 8, children: colors.map((c) => Chip(label: Text(c), backgroundColor: const Color(0xFFF1E7D8))).toList())),
          _section('Personality', Wrap(spacing: 8, runSpacing: 8, children: personality.map((p) => Chip(label: Text(p))).toList())),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
              onPressed: () async {
                final result = await context.push('/edit-brand', extra: brand);
                if (result == true) loadBrand();
              },
              child: const Text('Edit Store', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/create-listing'),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              final generatedBrand = GeneratedBrandModel(
                brandId: brand!['brandId'] ?? '',
                brandName: brand!['brandName'] ?? '',
                tagline: brand!['tagline'] ?? '',
                description: brand!['description'] ?? '',
                colors: List<String>.from(brand!['colors'] ?? []),
                personalityTraits: List<String>.from(brand!['personalityTraits'] ?? []),
                targetAudience: List<String>.from(brand!['targetAudience'] ?? []),
                brandScore: brand!['brandScore'] ?? 90,
              );
              context.push('/ai-logo-generation', extra: generatedBrand);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate AI Logo'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6DED2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 10), child]),
      );
}
