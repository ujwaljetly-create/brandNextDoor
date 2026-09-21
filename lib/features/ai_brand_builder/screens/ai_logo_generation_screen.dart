import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ai_logo/services/ai_logo_service.dart';
import '../../brand/services/brand_service.dart';
import '../models/generated_brand_model.dart';

class AILogoGenerationScreen extends StatefulWidget {
  final GeneratedBrandModel brand;
  const AILogoGenerationScreen({super.key, required this.brand});

  @override
  State<AILogoGenerationScreen> createState() => _AILogoGenerationScreenState();
}

class _AILogoGenerationScreenState extends State<AILogoGenerationScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  bool isGenerating = false;
  bool isSaving = false;
  String? generatedLogo;
  String? error;

  @override
  void initState() {
    super.initState();
    generateLogo();
  }

  Future<void> generateLogo() async {
    if (isGenerating) return;
    setState(() {
      isGenerating = true;
      error = null;
      generatedLogo = null;
    });
    try {
      final result = await AILogoService().generateLogo(
        brandName: widget.brand.brandName,
        tagline: widget.brand.tagline,
        description: widget.brand.description,
        colors: widget.brand.colors,
      );
      if (!mounted) return;
      setState(() => generatedLogo = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'We could not generate a logo. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI logo generation failed: $e')),
      );
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  Future<void> saveLogo() async {
    if (generatedLogo == null || isSaving) return;
    final id = widget.brand.brandId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save the brand before choosing a logo.')),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      final Uint8List bytes = base64Decode(generatedLogo!);
      await BrandService().saveBrandLogo(brandId: id, bytes: bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New logo saved to your brand.')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save logo: $e')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void keepCurrentLogo() {
    if (context.canPop()) {
      context.pop(false);
    } else {
      context.go('/seller-brand');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _navy),
          onPressed: keepCurrentLogo,
        ),
        title: const Text(
          'AI Logo Generator',
          style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Text(
              widget.brand.brandName,
              style: const TextStyle(
                color: _navy,
                fontFamily: 'serif',
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.brand.tagline.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(widget.brand.tagline, style: const TextStyle(color: Color(0xFF65727A))),
            ],
            const SizedBox(height: 20),
            Container(
              height: 330,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE5D9C8)),
              ),
              child: Center(
                child: isGenerating
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _gold),
                          SizedBox(height: 18),
                          Text(
                            'Creating a logo for your brand...',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _navy, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : generatedLogo != null
                        ? Image.memory(
                            base64Decode(generatedLogo!),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: _navy,
                              size: 60,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: _gold, size: 48),
                              const SizedBox(height: 14),
                              Text(
                                error ?? 'No logo generated yet.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _navy),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: isGenerating || isSaving ? null : generateLogo,
              icon: const Icon(Icons.refresh),
              label: const Text('Generate Another'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: isSaving ? null : keepCurrentLogo,
              icon: const Icon(Icons.undo),
              label: const Text('Keep Using Current Logo'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: generatedLogo == null || isSaving ? null : saveLogo,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(isSaving ? 'Saving Logo...' : 'Use This Logo'),
            ),
          ],
        ),
      ),
    );
  }
}
