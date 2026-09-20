import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/city_picker_sheet.dart';
import '../services/brand_service.dart';

class EditBrandScreen extends StatefulWidget {
  final Map<String, dynamic> brand;

  const EditBrandScreen({
    super.key,
    required this.brand,
  });

  @override
  State<EditBrandScreen> createState() => _EditBrandScreenState();
}

class _EditBrandScreenState extends State<EditBrandScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  late final TextEditingController brandController;
  late final TextEditingController taglineController;
  late final TextEditingController descriptionController;
  late final TextEditingController cityController;

  bool isSaving = false;
  late List<String> selectedColors;

  static const _palette = <String, String>{
    'Navy': '#0C2430',
    'Gold': '#C99245',
    'Ivory': '#F8F3EA',
    'Forest Green': '#355E4A',
    'Terracotta': '#B9674D',
    'Dusty Rose': '#C98C8C',
    'Slate Blue': '#5C6F91',
    'Charcoal': '#3B4145',
  };

  @override
  void initState() {
    super.initState();
    brandController = TextEditingController(
      text: (widget.brand['brandName'] ?? '').toString(),
    );
    taglineController = TextEditingController(
      text: (widget.brand['tagline'] ?? '').toString(),
    );
    descriptionController = TextEditingController(
      text: (widget.brand['description'] ?? '').toString(),
    );
    cityController = TextEditingController(
      text: (widget.brand['city'] ?? '').toString(),
    );
    selectedColors = List<String>.from(widget.brand['colors'] ?? const <String>[])
        .where((color) => _palette.values.any((v) => v.toUpperCase() == color.toUpperCase()))
        .map((color) => _palette.values.firstWhere((v) => v.toUpperCase() == color.toUpperCase()))
        .take(3)
        .toList();
  }

  Future<void> _chooseCity() async {
    final result = await CityPickerSheet.show(
      context,
      initialCity: cityController.text.trim(),
    );
    if (result != null) {
      cityController.text = result.city;
      if (mounted) setState(() {});
    }
  }

  Future<void> save() async {
    if (brandController.text.trim().isEmpty || cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand name and city are required.')),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      await BrandService().updateBrand(
        brandId: (widget.brand['brandId'] ?? '').toString(),
        brandName: brandController.text.trim(),
        tagline: taglineController.text.trim(),
        description: descriptionController.text.trim(),
        city: cityController.text.trim(),
        colors: selectedColors,
      );
      if (!mounted) return;
      context.pop(true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    brandController.dispose();
    taglineController.dispose();
    descriptionController.dispose();
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: const Text(
          'Edit Brand',
          style: TextStyle(
            color: _navy,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: brandController,
            decoration: const InputDecoration(labelText: 'Brand Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: taglineController,
            decoration: const InputDecoration(labelText: 'Tagline'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _chooseCity,
            borderRadius: BorderRadius.circular(14),
            child: IgnorePointer(
              child: TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Use GPS or search for a city',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  suffixIcon: Icon(Icons.map_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Brand Colors', style: TextStyle(color: _navy, fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Choose up to three colors. AI logo generation will use these brand colors.', style: TextStyle(color: Color(0xFF68747A), height: 1.35)),
          const SizedBox(height: 12),
          Wrap(spacing: 9, runSpacing: 9, children: _palette.entries.map((entry) {
            final selected = selectedColors.contains(entry.value);
            return FilterChip(
              selected: selected,
              selectedColor: const Color(0xFFEAD8BA),
              checkmarkColor: _navy,
              avatar: CircleAvatar(backgroundColor: _hex(entry.value)),
              label: Text(entry.key, style: const TextStyle(color: _navy)),
              onSelected: (value) {
                setState(() {
                  if (value) {
                    if (selectedColors.length < 3) selectedColors.add(entry.value);
                  } else {
                    selectedColors.remove(entry.value);
                  }
                });
              },
            );
          }).toList()),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving ? null : save,
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
  Color _hex(String value) => Color(int.parse('FF${value.replaceAll('#', '')}', radix: 16));

}
