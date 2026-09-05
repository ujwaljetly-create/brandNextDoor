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
class CreateListingScreen
    extends StatefulWidget {

  final GeneratedListingModel?
      generatedListing;

  const CreateListingScreen({
    super.key,
    this.generatedListing,
  });

  @override
  State<CreateListingScreen> createState() =>
      _CreateListingScreenState();
      
}

class _CreateListingScreenState
    extends State<CreateListingScreen> {
      @override
void initState() {
  super.initState();

  final listing =
      widget.generatedListing;

  if (listing != null) {
    titleController.text =
        listing.title;

    descriptionController.text =
        listing.description;

    priceController.text =
        listing.suggestedPrice
            .toStringAsFixed(2);
  }
}
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController =
      TextEditingController();
  final priceController = TextEditingController();

  bool deliveryAvailable = true;
  bool pickupAvailable = false;

  bool isLoading = false;

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

  Future<void> pickImages() async {
    final picker = ImagePicker();

    final images =
        await picker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() {
      selectedImages.addAll(
        images.map((e) => File(e.path)),
      );
    });
  }

  Future<void> createListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Replace later with Firebase Storage URLs
      final storageService =
    StorageService();

List<String> imageUrls = [];

for (final image
    in selectedImages) {
  final url =
      await storageService.uploadImage(
    image,
    'listing_images',
  );

  imageUrls.add(url);
}
final user =
    FirebaseAuth.instance.currentUser;

final brand =
    await BrandService()
        .getSellerBrand();

if (user == null ||
    brand == null) {
  throw Exception(
    'Brand not found',
  );
}
      final listing = ListingModel(
        listingId: const Uuid().v4(),
        sellerId:
      user.uid,

  brandId:
      brand['brandId'],
        title: titleController.text.trim(),
        description:
            descriptionController.text.trim(),
        price: double.parse(
          priceController.text.trim(),
        ),
        images: imageUrls,
        deliveryAvailable:
            deliveryAvailable,
        pickupAvailable:
            pickupAvailable,
        category: selectedCategory,
        status: 'active',
        createdAt: Timestamp.now(),
      );

      await ListingService()
          .createListing(listing);

      if (!mounted) return;

      if (!mounted) return;

ScaffoldMessenger.of(context)
    .showSnackBar(
  const SnackBar(
    content: Text(
      'Listing Created Successfully',
    ),
  ),
);

context.go(
  '/my-listings',
);

      //Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Create Listing'),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () {
        context.push(
          '/ai-listing-builder',
        );
      },
      icon: const Icon(
        Icons.auto_awesome,
      ),
      label: const Text(
        'Create With AI',
      ),
    ),
  ),

  const SizedBox(
    height: 24,
  ),

  TextFormField(
    controller: titleController,
    style: const TextStyle(color: Colors.white),
    cursorColor: Colors.white,
    decoration: InputDecoration(
      labelText: 'Title',
      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) {
        return 'Enter title';
      }
      return null;
    },
  ),

  const SizedBox(
    height: 16,
  ),

  TextFormField(
    controller:
        descriptionController,
    maxLines: 5,
    style: const TextStyle(color: Colors.white),
    cursorColor: Colors.white,
    decoration: InputDecoration(
      labelText: 'Description',
      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
    ),
  ),

  const SizedBox(
    height: 16,
  ),

  TextFormField(
    controller: priceController,
    keyboardType:
        TextInputType.number,
    style: const TextStyle(color: Colors.white),
    cursorColor: Colors.white,
    decoration: InputDecoration(
      labelText: 'Price',
      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white),
      prefixStyle: const TextStyle(color: Colors.white),
      prefixText: '\$ ',
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
    ),
  ),

  const SizedBox(
    height: 16,
  ),

  DropdownButtonFormField<String>(
    value: selectedCategory,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: 'Category',
      labelStyle: const TextStyle(color: Colors.white),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
    ),
    items: categories
        .map(
          (e) => DropdownMenuItem(
            value: e,
            child: Text(
              e,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        )
        .toList(),
    onChanged: (value) {
      setState(() {
        selectedCategory = value!;
      });
    },
  ),

  const SizedBox(
    height: 20,
  ),

  SwitchListTile(
    title: const Text(
      'Delivery Available',
    ),
    value: deliveryAvailable,
    onChanged: (value) {
      setState(() {
        deliveryAvailable = value;
      });
    },
  ),

  SwitchListTile(
    title: const Text(
      'Pickup Available',
    ),
    value: pickupAvailable,
    onChanged: (value) {
      setState(() {
        pickupAvailable = value;
      });
    },
  ),

  const SizedBox(
    height: 20,
  ),

  ElevatedButton.icon(
    onPressed: pickImages,
    icon: const Icon(
      Icons.photo,
    ),
    label: const Text(
      'Select Images',
    ),
  ),

  const SizedBox(
    height: 16,
  ),

  if (selectedImages.isNotEmpty)
    SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            selectedImages.length,
        itemBuilder:
            (context, index) {
          return Padding(
            padding:
                const EdgeInsets.only(
              right: 10,
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
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

  const SizedBox(
    height: 30,
  ),

  SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton.icon(
      onPressed: createListing,
      icon: const Icon(
        Icons.publish,
      ),
      label: const Text(
        'Publish Listing',
      ),
    ),
  ),

  const SizedBox(
    height: 40,
  ),
],
                ),
              ),
            ),
    );
  }
}