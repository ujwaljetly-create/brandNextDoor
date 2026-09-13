import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/generated_listing_model.dart';
import '../services/ai_listing_service.dart';

class AIListingBuilderScreen extends StatefulWidget {
  const AIListingBuilderScreen({super.key});

  @override
  State<AIListingBuilderScreen> createState() => _AIListingBuilderScreenState();
}

class _AIListingBuilderScreenState extends State<AIListingBuilderScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  final descriptionController = TextEditingController();
  bool isGenerating = false;

  Future<void> generateListing() async {
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tell us about your product.')),
      );
      return;
    }

    setState(() => isGenerating = true);
    try {
      final GeneratedListingModel listing =
          await AIListingService().generateListing(descriptionController.text.trim());
      if (!mounted) return;
      context.push('/ai-listing-result', extra: listing);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isGenerating) return _progressScreen();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: _navy),
        ),
        title: const Text('Create with AI', style: TextStyle(color: _navy, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  const Text(
                    'Tell us about\nyour product',
                    style: TextStyle(color: _navy, fontFamily: 'serif', fontSize: 34, height: 1.05, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share the basics and AI will create a polished local-market listing with title, description, tags and pricing guidance.',
                    style: TextStyle(color: Color(0xFF66727A), fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4DDD2)),
                    ),
                    child: TextField(
                      controller: descriptionController,
                      maxLines: 9,
                      style: const TextStyle(color: _navy),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Example:\nHandmade soy candle with lavender scent, eco-friendly packaging, locally made in Toronto. Great for gifts and home decor.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _AiBenefit(Icons.auto_awesome, 'Generate a compelling title & description'),
                  const _AiBenefit(Icons.sell_outlined, 'Suggest useful categories & tags'),
                  const _AiBenefit(Icons.attach_money, 'Recommend a competitive price'),
                  const _AiBenefit(Icons.search, 'Optimize for local discovery'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
                  onPressed: generateListing,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate with AI', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressScreen() {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 5),
                  gradient: const RadialGradient(colors: [Colors.white, Color(0xFFF3E8D9)]),
                ),
                child: const Center(
                  child: Text('Let AI\ndo the rest', textAlign: TextAlign.center, style: TextStyle(color: _navy, fontFamily: 'serif', fontSize: 29, height: 1.05, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Creating your product listing\nwith compelling copy, tags, and suggestions...', textAlign: TextAlign.center, style: TextStyle(color: _navy, fontSize: 17, height: 1.4)),
              const SizedBox(height: 28),
              const LinearProgressIndicator(color: _gold, backgroundColor: Color(0xFFE9DED0)),
              const SizedBox(height: 28),
              const _Progress('Analyzing product details'),
              const _Progress('Generating title & description'),
              const _Progress('Suggesting category & tags'),
              const _Progress('Optimizing for local search'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiBenefit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _AiBenefit(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC99245), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF0C2430), fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final String text;
  const _Progress(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFC99245), size: 20),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(color: Color(0xFF0C2430), fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
