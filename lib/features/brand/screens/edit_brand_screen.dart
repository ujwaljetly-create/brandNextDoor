import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/openai_service.dart';
import '../../../widgets/city_picker_sheet.dart';
import '../services/brand_service.dart';

class EditBrandScreen extends StatefulWidget {
  final Map<String, dynamic> brand;
  const EditBrandScreen({super.key, required this.brand});

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
  bool isResolvingColor = false;
  late List<String> selectedColors;
  late Map<String, String> colorNames;

  @override
  void initState() {
    super.initState();
    brandController = TextEditingController(text: (widget.brand['brandName'] ?? '').toString());
    taglineController = TextEditingController(text: (widget.brand['tagline'] ?? '').toString());
    descriptionController = TextEditingController(text: (widget.brand['description'] ?? '').toString());
    cityController = TextEditingController(text: (widget.brand['city'] ?? '').toString());
    selectedColors = List<String>.from(widget.brand['colors'] ?? const <String>[]).take(5).toList();
    final rawNames = widget.brand['colorNames'];
    colorNames = rawNames is Map
        ? rawNames.map((key, value) => MapEntry(key.toString(), value.toString()))
        : <String, String>{};
  }

  Future<void> _chooseCity() async {
    final result = await CityPickerSheet.show(context, initialCity: cityController.text.trim());
    if (result != null) {
      cityController.text = result.city;
      if (mounted) setState(() {});
    }
  }

  Future<void> _addColor() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Brand Color', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Color name',
            hintText: 'e.g. Sage green, warm coral',
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _navy),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Generate Color'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;

    setState(() => isResolvingColor = true);
    try {
      final hex = await OpenAIService().resolveColorHex(name.trim());
      if (!mounted) return;
      setState(() {
        if (!selectedColors.contains(hex)) selectedColors.add(hex);
        colorNames[hex] = name.trim();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create that color: $e')));
      }
    } finally {
      if (mounted) setState(() => isResolvingColor = false);
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
        colorNames: colorNames,
      );
      if (mounted) context.pop(true);
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

  Color _hex(String value) {
    final clean = value.replaceAll('#', '');
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(clean)) return _navy;
    return Color(int.parse('FF$clean', radix: 16));
  }

  String _fallbackColorName(String hex) {
    const known = {
      '#0C2430': 'Navy',
      '#C99245': 'Gold',
      '#F8F3EA': 'Ivory',
      '#355E4A': 'Forest Green',
      '#B9674D': 'Terracotta',
      '#C98C8C': 'Dusty Rose',
      '#5C6F91': 'Slate Blue',
      '#3B4145': 'Charcoal',
    };
    return colorNames[hex] ?? known[hex.toUpperCase()] ?? 'Brand Color';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        title: const Text('Edit Brand', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Brand Name')),
          const SizedBox(height: 16),
          TextField(controller: taglineController, decoration: const InputDecoration(labelText: 'Tagline')),
          const SizedBox(height: 16),
          TextField(controller: descriptionController, maxLines: 5, decoration: const InputDecoration(labelText: 'Description')),
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
          const SizedBox(height: 24),
          const Text('Brand Colors', style: TextStyle(color: _navy, fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Your selected colors are used by AI when generating your brand logo.', style: TextStyle(color: Color(0xFF68747A), height: 1.35)),
          const SizedBox(height: 12),
          if (selectedColors.isEmpty)
            const Text('No brand colors selected yet.', style: TextStyle(color: Color(0xFF68747A)))
          else
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: selectedColors.map((hex) => InputChip(
                avatar: CircleAvatar(backgroundColor: _hex(hex)),
                label: Text(_fallbackColorName(hex), style: const TextStyle(color: _navy)),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE6DED2)),
                deleteIconColor: _navy,
                onDeleted: () => setState(() {
                  selectedColors.remove(hex);
                  colorNames.remove(hex);
                }),
              )).toList(),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy,
                side: const BorderSide(color: _gold),
                minimumSize: const Size(0, 48),
              ),
              onPressed: isResolvingColor ? null : _addColor,
              icon: isResolvingColor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
                  : const Icon(Icons.add),
              label: Text(isResolvingColor ? 'Creating Color...' : 'Add More Colors'),
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
              onPressed: isSaving ? null : save,
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
