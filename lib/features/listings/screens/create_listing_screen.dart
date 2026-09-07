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

  const CreateListingScreen({
    super.key,
    this.generatedListing,
  });

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final cityController = TextEditingController();
  final dealPriceController = TextEditingController();

  bool deliveryAvailable = true;
  bool pickupAvailable = false;
  bool isHotDeal = false;
  bool isLoading = false;

  DateTime? dealStartDate;
  DateTime? dealEndDate;

  String selectedCategory = 'Fashion';

  final List<String> categories = [
    'Fashion',
    'Food',
    'Home Decor',
    'Beauty',
    'Services',
    'Electronics',
  ];

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
      if (city.isNotEmpty) {
        cityController.text = city;
      }
    } catch (_) {}
  }

  Future<void> pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      selectedImages.addAll(images.map((e) => File(e.path)));
    });
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

    if (price == null || price <= 0) {
      _message('Enter a valid price.');
      return;
    }

    if (isHotDeal) {
      if (dealPrice <= 0 || dealPrice >= price) {
        _message('Deal price must be greater than 0 and lower than regular price.');
        return;
      }
      if (dealStartDate == null || dealEndDate == null) {
        _message('Choose a start and end date for the hot deal.');
        return;
      }
      if (dealEndDate!.isBefore(dealStartDate!)) {
        _message('Deal end date must be after the start date.');
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      final storageService = StorageService();
      final imageUrls = <String>[];

      for (final image in selectedImages) {
        imageUrls.add(
          await storageService.uploadImage(image, 'listing_images'),
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      final brand = await BrandService().getSellerBrand();

      if (user == null || brand == null) {
        throw Exception('Brand not found');
      }

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
            ? Timestamp.fromDate(DateTime(
                dealStartDate!.year,
                dealStartDate!.month,
                dealStartDate!.day,
              ))
            : null,
        dealEndAt: isHotDeal && dealEndDate != null
            ? Timestamp.fromDate(DateTime(
                dealEndDate!.year,
                dealEndDate!.month,
                dealEndDate!.day,
                23,
                59,
                59,
              ))
            : null,
        createdAt: Timestamp.now(),
      );

      await ListingService().createListing(listing);

      if (!mounted) return;
      _message('Listing created successfully.');
      context.go('/my-listings');
    } catch (e) {
      if (!mounted) return;
      _message(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
      appBar: AppBar(
        title: const Text('Create Listing'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/ai-listing-builder');
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Create With AI'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter title'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Regular price',
                      prefixText: '\$ ',
                    ),
                    validator: (value) =>
                        double.tryParse(value?.trim() ?? '') == null
                            ? 'Enter a valid price'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the city for this listing'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Delivery Available'),
                    value: deliveryAvailable,
                    onChanged: (value) {
                      setState(() {
                        deliveryAvailable = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pickup Available'),
                    value: pickupAvailable,
                    onChanged: (value) {
                      setState(() {
                        pickupAvailable = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Hot Deal',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Feature this listing in Hot deals near me.',
                            ),
                            value: isHotDeal,
                            onChanged: (value) {
                              setState(() {
                                isHotDeal = value;
                              });
                            },
                          ),
                          if (isHotDeal) ...[
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: dealPriceController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Deal price',
                                prefixText: '\$ ',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final date = await _pickDate(dealStartDate);
                                      if (date != null && mounted) {
                                        setState(() {
                                          dealStartDate = date;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.calendar_today_outlined),
                                    label: Text(
                                      dealStartDate == null
                                          ? 'Start date'
                                          : '${dealStartDate!.year}-${dealStartDate!.month.toString().padLeft(2, '0')}-${dealStartDate!.day.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final date = await _pickDate(dealEndDate);
                                      if (date != null && mounted) {
                                        setState(() {
                                          dealEndDate = date;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.event_outlined),
                                    label: Text(
                                      dealEndDate == null
                                          ? 'End date'
                                          : '${dealEndDate!.year}-${dealEndDate!.month.toString().padLeft(2, '0')}-${dealEndDate!.day.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: pickImages,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Select Images'),
                  ),
                  if (selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImages[index],
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: createListing,
                      icon: const Icon(Icons.publish),
                      label: const Text('Publish Listing'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
