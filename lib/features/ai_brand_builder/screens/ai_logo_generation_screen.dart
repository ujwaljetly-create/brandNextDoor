import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ai_logo/services/ai_logo_service.dart';
import '../../brand/services/brand_service.dart';
import '../models/generated_brand_model.dart';

class AILogoGenerationScreen
    extends StatefulWidget {
  final GeneratedBrandModel brand;

  const AILogoGenerationScreen({
    super.key,
    required this.brand,
  });

  @override
  State<AILogoGenerationScreen>
      createState() =>
          _AILogoGenerationScreenState();
}

class _AILogoGenerationScreenState
    extends State<AILogoGenerationScreen> {
  bool isGenerating = false;

  bool isSaving = false;

  String? generatedLogo;

  @override
  void initState() {
    super.initState();

    generateLogo();
  }

  Future<void> generateLogo() async {
    try {
      setState(() {
        isGenerating = true;
      });

      final result =
          await AILogoService()
              .generateLogo(
        brandName:
            widget.brand.brandName,
        tagline:
            widget.brand.tagline,
        description:
            widget.brand.description,
        colors:
            widget.brand.colors,
      );

      if (!mounted) return;

      setState(() {
        generatedLogo = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  Future<void> saveLogo() async {
  try {
    if (generatedLogo == null) {
      return;
    }

    debugPrint(
      'BrandId = ${widget.brand.brandId}',
    );

    if (widget.brand.brandId == null ||
        widget.brand.brandId!.isEmpty) {
      throw Exception(
        'Brand must be saved before a logo can be attached.',
      );
    }

    setState(() {
      isSaving = true;
    });

    final Uint8List bytes =
        base64Decode(
      generatedLogo!,
    );

    await BrandService()
        .saveBrandLogo(
      brandId:
          widget.brand.brandId!,
      bytes: bytes,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Logo Saved Successfully',
        ),
      ),
    );

    context.pop(true);

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(e.toString()),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }
}


  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          'AI Logo Generator',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.brand.brandName,
              style:
                  const TextStyle(
                fontSize: 30,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.white,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              widget.brand.tagline,
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            Container(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius
                        .circular(
                  24,
                ),
                color:
                    Colors.white10,
              ),
              child: Text(
                widget.brand
                    .description,
                style:
                    const TextStyle(
                  color:
                      Colors.white70,
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            Expanded(
              child: Center(
                child:
                    isGenerating
                        ? Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(
                                height:
                                    20,
                              ),
                              Text(
                                'Generating logo...',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ],
                          )
                        : generatedLogo ==
                                null
                            ? const Text(
                                'Failed to generate logo',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                ),
                              )
                            : ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                  24,
                                ),
                                child:
                                    Image.memory(
                                  base64Decode(
                                    generatedLogo!,
                                  ),
                                  fit: BoxFit
                                      .contain,
                                ),
                              ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    isGenerating ||
                            isSaving
                        ? null
                        : generateLogo,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Generate Another',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 55,
              child:
                  ElevatedButton.icon(
                onPressed:
                    generatedLogo ==
                                null ||
                            isSaving
                        ? null
                        : saveLogo,
                icon:
                    isSaving
                        ? const SizedBox(
                            height:
                                18,
                            width:
                                18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons.check,
                          ),
                label: Text(
                  isSaving
                      ? 'Saving Logo...'
                      : 'Use This Logo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}