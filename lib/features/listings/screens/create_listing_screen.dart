import 'dart:io';

import 'package:brand_next_door/services/storage/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../models/listing_model.dart';
import '../../brand/services/brand_service.dart';
import '../models/generated_listing_model.dart';
import '../services/listing_service.dart';

class CreateListingScreen extends StatefulWidget {
  final GeneratedListingModel? generatedListing;

  const CreateListingScreen({super.key, this.generatedListing});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final cityController = TextEditingController();
  final dealPriceController = TextEditingController();

  bool deliveryAvailable = true;
  bool pickupAvailable = false;
  bool isHotDeal = false;
  bool useAi = false;
  bool isLoading = false;
  DateTime? dealStartDate;
  DateTime? dealEndDate;
  String selectedCategory = 'Fashion';

  final categories = const ['Fashion', 'Food', 'Home Decor', 'Beauty', 'Services', 'Electronics'];
  final List<File> selectedImages = [];

  @override
  void initState() {
    super.initState();
    final generated = widget.generatedListing;
    if (generated != null) {
      titleController.text = generated.title;
      descriptionController.text = generated.description;
      priceController.text = generated.suggestedPrice.toStringAsFixed(2);
    }
    _loadBrandCity();
  }

  Future<void> _loadBrandCity() async {
    try {
      final brand = await BrandService().getSellerBrand();
      if (!mounted || cityController.text.trim().isNotEmpty) return;
      final city = (brand?['city'] ?? '').toString().trim();
      if (city.isNotEmpty) cityController.text = city;
    } catch (_) {}
  }

  Future<void> pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    if (images.isEmpty) return;
    setState(() => selectedImages.addAll(images.map((e) => File(e.path))));
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
  }

  Future<void> createListing() async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(priceController.text.trim());
    final dealPrice = double.tryParse(dealPriceController.text.trim()) ?? 0;
    if (price == null || price <= 0) return _message('Enter a valid price.');
    if (isHotDeal) {
      if (dealPrice <= 0 || dealPrice >= price) return _message('Deal price must be lower than the regular price.');
      if (dealStartDate == null || dealEndDate == null) return _message('Choose deal start and end dates.');
      if (dealEndDate!.isBefore(dealStartDate!)) return _message('Deal end date must be after the start date.');
    }

    setState(() => isLoading = true);
    try {
      final imageUrls = <String>[];
      for (final image in selectedImages) {
        imageUrls.add(await StorageService().uploadImage(image, 'listing_images'));
      }
      final user = FirebaseAuth.instance.currentUser;
      final brand = await BrandService().getSellerBrand();
      if (user == null || brand == null) throw Exception('Brand not found');

      final listing = ListingModel(
        listingId: const Uuid().v4(),
        sellerId: user.uid,
        brandId: (brand['brandId'] ?? '').toString(),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price: price,
        images: imageUrls,
        deliveryAvailable: deliveryAvailable,
        pickupAvailable: pickupAvailable,
        category: selectedCategory,
        status: 'active',
        city: cityController.text.trim(),
        isHotDeal: isHotDeal,
        dealPrice: isHotDeal ? dealPrice : 0,
        dealStartAt: isHotDeal && dealStartDate != null
            ? Timestamp.fromDate(DateTime(dealStartDate!.year, dealStartDate!.month, dealStartDate!.day))
            : null,
        dealEndAt: isHotDeal && dealEndDate != null
            ? Timestamp.fromDate(DateTime(dealEndDate!.year, dealEndDate!.month, dealEndDate!.day, 23, 59, 59))
            : null,
        createdAt: Timestamp.now(),
      );

      await ListingService().createListing(listing);
      if (!mounted) return;
      _message('Listing created successfully.');
      context.go('/my-listings');
    } catch (e) {
      if (mounted) _message(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    cityController.dispose();
    dealPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: _navy)),
        title: const Text('Add a Product', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _photoStrip(),
                  const SizedBox(height: 18),
                  _field(titleController, 'Product Title', validator: true),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: _decoration('Category'),
                    items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) => setState(() => selectedCategory = value ?? selectedCategory),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(priceController, 'Price (CAD)', number: true, validator: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(cityController, 'City', validator: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 5,
                    decoration: _decoration('Description'),
                  ),
                  const SizedBox(height: 12),
                  _switch('Available for local delivery', deliveryAvailable, (v) => setState(() => deliveryAvailable = v)),
                  _switch('Available for local pickup', pickupAvailable, (v) => setState(() => pickupAvailable = v)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6DED2))),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Use AI to generate listing', style: TextStyle(color: _navy, fontWeight: FontWeight.w700)),
                          subtitle: const Text('Let AI write and optimize your product listing.', style: TextStyle(fontSize: 12)),
                          value: useAi,
                          activeThumbColor: _gold,
                          onChanged: (v) => setState(() => useAi = v),
                        ),
                        if (useAi)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/ai-listing-builder'),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Generate with AI'),
                            ),
                          ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Make this a Hot Deal', style: TextStyle(color: _navy, fontWeight: FontWeight.w700)),
                          subtitle: const Text('Feature this item in Hot deals near me.', style: TextStyle(fontSize: 12)),
                          value: isHotDeal,
                          activeThumbColor: _gold,
                          onChanged: (v) => setState(() => isHotDeal = v),
                        ),
                        if (isHotDeal) ...[
                          _field(dealPriceController, 'Deal Price', number: true),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _dateButton('Start date', dealStartDate, () async {
                                final date = await _pickDate(dealStartDate);
                                if (date != null) setState(() => dealStartDate = date);
                              })),
                              const SizedBox(width: 8),
                              Expanded(child: _dateButton('End date', dealEndDate, () async {
                                final date = await _pickDate(dealEndDate);
                                if (date != null) setState(() => dealEndDate = date);
                              })),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
                      onPressed: createListing,
                      child: const Text('List Product', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _photoStrip() {
    return SizedBox(
      height: 170,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: pickImages,
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFE7D8C2), borderRadius: BorderRadius.circular(16)),
                child: selectedImages.isEmpty
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_a_photo_outlined, color: _navy, size: 38), SizedBox(height: 8), Text('Add Photos', style: TextStyle(color: _navy, fontWeight: FontWeight.w700))]))
                    : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(selectedImages.first, fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _thumb(1)),
                const SizedBox(height: 10),
                Expanded(
                  child: InkWell(
                    onTap: pickImages,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE6DED2))),
                      child: const Center(child: Icon(Icons.add, color: _navy)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(int index) {
    if (selectedImages.length <= index) {
      return Container(decoration: BoxDecoration(color: const Color(0xFFF1E8DB), borderRadius: BorderRadius.circular(14)), child: const Center(child: Icon(Icons.image_outlined, color: _navy)));
    }
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(selectedImages[index], fit: BoxFit.cover, width: double.infinity));
  }

  Widget _field(TextEditingController controller, String label, {bool number = false, bool validator = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
      decoration: _decoration(label),
      validator: validator
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF68747A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE6DED2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE6DED2))),
      );

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(color: _navy, fontWeight: FontWeight.w600)),
        value: value,
        activeThumbColor: _gold,
        onChanged: onChanged,
      );

  Widget _dateButton(String label, DateTime? date, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_today_outlined, size: 17),
        label: Text(date == null ? label : '${date.month}/${date.day}/${date.year}', maxLines: 1, overflow: TextOverflow.ellipsis),
      );
}
