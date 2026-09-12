import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/openai_service.dart';
import '../../brand/services/brand_service.dart';
import '../models/generated_brand_model.dart';

class AIBrandStudioScreen extends StatefulWidget {
  final GeneratedBrandModel brand;

  const AIBrandStudioScreen({super.key, required this.brand});

  @override
  State<AIBrandStudioScreen> createState() => _AIBrandStudioScreenState();
}

class _AIBrandStudioScreenState extends State<AIBrandStudioScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  bool isSaving = false;
  bool isGenerating = false;
  String? savedBrandId;

  late String brandName;
  late String tagline;
  late String description;
  late List<String> colors;
  late List<String> audience;
  late List<String> personality;

  @override
  void initState() {
    super.initState();
    brandName = widget.brand.brandName;
    tagline = widget.brand.tagline;
    description = widget.brand.description;
    colors = List<String>.from(widget.brand.colors);
    audience = List<String>.from(widget.brand.targetAudience);
    personality = List<String>.from(widget.brand.personalityTraits);
    savedBrandId = widget.brand.brandId;
  }

  GeneratedBrandModel _currentBrand({String? brandId}) => GeneratedBrandModel(
        brandId: brandId ?? savedBrandId,
        brandName: brandName,
        tagline: tagline,
        description: description,
        colors: colors,
        personalityTraits: personality,
        targetAudience: audience,
        brandScore: widget.brand.brandScore,
      );

  Future<void> _editBrand() async {
    final name = TextEditingController(text: brandName);
    final line = TextEditingController(text: tagline);
    final desc = TextEditingController(text: description);

    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          6,
          22,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Brand Details', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: _navy)),
              const SizedBox(height: 18),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Brand Name')),
              const SizedBox(height: 12),
              TextField(controller: line, decoration: const InputDecoration(labelText: 'Tagline')),
              const SizedBox(height: 12),
              TextField(controller: desc, maxLines: 5, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _gold),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (save == true) {
      setState(() {
        brandName = name.text.trim();
        tagline = line.text.trim();
        description = desc.text.trim();
      });
    }
    name.dispose();
    line.dispose();
    desc.dispose();
  }

  Future<void> _regenerateName() async {
    setState(() => isGenerating = true);
    try {
      brandName = await OpenAIService().generateBrandName(description);
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  Future<void> _regenerateTagline() async {
    setState(() => isGenerating = true);
    try {
      tagline = await OpenAIService().generateTagline(description);
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  Future<void> _improveDescription() async {
    setState(() => isGenerating = true);
    try {
      description = await OpenAIService().generateDescription(description);
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  Future<String> _ensureSaved() async {
    if (savedBrandId != null && savedBrandId!.isNotEmpty) return savedBrandId!;
    final id = await BrandService().saveGeneratedBrand(_currentBrand());
    savedBrandId = id;
    return id;
  }

  Future<void> _generateLogo() async {
    setState(() => isSaving = true);
    try {
      final id = await _ensureSaved();
      if (!mounted) return;
      await context.push('/ai-logo-generation', extra: _currentBrand(brandId: id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not prepare logo generation: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _continue() async {
    setState(() => isSaving = true);
    try {
      await _ensureSaved();
      if (!mounted) return;
      context.go('/seller-dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save brand: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: _navy),
        ),
        title: const Text('Your Brand is Ready!', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text('Here’s what we created for you.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF67747B))),
          const SizedBox(height: 18),
          Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFFF1DEC0), Color(0xFFE2C79D)]),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_florist_outlined, color: _navy, size: 50),
                  const SizedBox(height: 12),
                  Text(brandName.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 29, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(height: 5),
                  Text(tagline, textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _section(
            title: 'Brand Colors',
            action: null,
            child: Wrap(
              spacing: 9,
              runSpacing: 9,
              children: colors.map((c) => Chip(label: Text(c), backgroundColor: const Color(0xFFF1E7D8))).toList(),
            ),
          ),
          _section(
            title: 'Tagline',
            action: TextButton(onPressed: isGenerating ? null : _regenerateTagline, child: const Text('Try another')),
            child: Text(tagline, style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          _section(
            title: 'Description',
            action: TextButton(onPressed: isGenerating ? null : _improveDescription, child: const Text('Improve')),
            child: Text(description, style: const TextStyle(color: _navy, fontSize: 15, height: 1.5)),
          ),
          _section(
            title: 'Brand Personality',
            action: null,
            child: Wrap(spacing: 8, runSpacing: 8, children: personality.map((item) => Chip(label: Text(item))).toList()),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isGenerating ? null : _regenerateName,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Another Brand Name'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _editBrand,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Details'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isSaving ? null : _generateLogo,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Logo with AI'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
              onPressed: isSaving ? null : _continue,
              child: isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continue to Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child, Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7DED2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w700))),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
