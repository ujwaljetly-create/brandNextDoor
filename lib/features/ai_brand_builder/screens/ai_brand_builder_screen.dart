import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/ai_brand_service.dart';

class AIBrandBuilderScreen extends StatefulWidget {
  const AIBrandBuilderScreen({super.key});

  @override
  State<AIBrandBuilderScreen> createState() => _AIBrandBuilderScreenState();
}

class _AIBrandBuilderScreenState extends State<AIBrandBuilderScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  final businessNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController(text: 'Toronto, ON');

  String businessType = 'Fashion & Accessories';
  bool useAi = true;
  bool isLoading = false;
  String logoChoice = 'ai';

  final businessTypes = const [
    'Fashion & Accessories',
    'Food & Beverage',
    'Beauty & Wellness',
    'Home & Decor',
    'Services',
    'Art & Handmade',
    'Other',
  ];

  @override
  void dispose() {
    businessNameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> generateBrand() async {
    if (businessNameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your business name and description.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final info = '''
Business name: ${businessNameController.text.trim()}
Business type: $businessType
Description: ${descriptionController.text.trim()}
Location: ${locationController.text.trim()}
Logo preference: ${logoChoice == 'ai' ? 'AI generated logo' : 'Seller will upload logo'}
Create a complete, premium local brand identity.
''';

      final result = await AIBrandService().generateBrand(businessInfo: info);
      if (!mounted) return;
      context.push('/ai-brand-studio', extra: result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not build your brand: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildProgress();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _navy),
          onPressed: () => context.canPop() ? context.pop() : context.go('/seller-onboarding'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  const Text(
                    'Tell us about\nyour business',
                    style: TextStyle(
                      color: _navy,
                      fontFamily: 'serif',
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: _chooseLogo,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9DDCB),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFD6C4A9)),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: _navy, size: 34),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            logoChoice == 'ai' ? 'AI will create your logo' : 'Upload your logo',
                            style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            onPressed: _chooseLogo,
                            child: const Text('Change logo option'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: businessNameController,
                    label: 'Business Name',
                    icon: Icons.business_center_outlined,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: businessType,
                    decoration: _decoration('Business Type', Icons.category_outlined),
                    items: businessTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => businessType = value ?? businessType),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: descriptionController,
                    label: 'Short Description',
                    icon: Icons.edit_note_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: locationController,
                    label: 'Location',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4DDD2)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Use AI to build my brand', style: TextStyle(color: _navy, fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('Let our AI create a complete identity based on your details.', style: TextStyle(color: Color(0xFF66727A), fontSize: 12)),
                            ],
                          ),
                        ),
                        Switch(
                          value: useAi,
                          activeThumbColor: _gold,
                          onChanged: (value) => setState(() => useAi = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: useAi ? generateBrand : () => context.push('/brand-profile'),
                  child: Text(useAi ? 'Build My Brand' : 'Continue Manually', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
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
                  gradient: const RadialGradient(colors: [Colors.white, Color(0xFFF4E9DB)]),
                ),
                child: const Center(
                  child: Text(
                    'Let AI\ndo the rest',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _navy, fontFamily: 'serif', fontSize: 29, height: 1.05, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              const Text(
                'Creating your brand identity,\nlogo, colors, and more...',
                textAlign: TextAlign.center,
                style: TextStyle(color: _navy, fontSize: 17, height: 1.45),
              ),
              const SizedBox(height: 30),
              const LinearProgressIndicator(color: _gold, backgroundColor: Color(0xFFE9DED0)),
              const SizedBox(height: 28),
              const _ProgressLine('Analyzing your business details'),
              const _ProgressLine('Generating brand identity'),
              const _ProgressLine('Creating logo options'),
              const _ProgressLine('Crafting your brand story'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: _navy),
      decoration: _decoration(label, icon),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF5F676D)),
      prefixIcon: Icon(icon, color: _navy),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4DDD2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4DDD2))),
    );
  }

  Future<void> _chooseLogo() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you like to create your logo?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Let AI generate it'),
                subtitle: const Text('Generate a logo after your brand identity is ready.'),
                onTap: () => Navigator.pop(context, 'ai'),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Upload it myself'),
                subtitle: const Text('You can upload your existing logo from My Brand.'),
                onTap: () => Navigator.pop(context, 'upload'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice != null) setState(() => logoChoice = choice);
  }
}

class _ProgressLine extends StatelessWidget {
  final String text;
  const _ProgressLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}
