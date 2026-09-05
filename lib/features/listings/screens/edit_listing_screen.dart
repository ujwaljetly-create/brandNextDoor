
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../services/listing_service.dart';

class EditListingScreen extends StatefulWidget {
  final ListingModel listing;

  const EditListingScreen({
    super.key,
    required this.listing,
  });

  @override
  State<EditListingScreen> createState() =>
      _EditListingScreenState();
}

class _EditListingScreenState
    extends State<EditListingScreen> {

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    titleController =
        TextEditingController(
      text: widget.listing.title,
    );

    descriptionController =
        TextEditingController(
      text: widget.listing.description,
    );

    priceController =
        TextEditingController(
      text: widget.listing.price.toString(),
    );
  }

  Future<void> saveChanges() async {
    try {
      setState(() {
        isSaving = true;
      });

      final updated =
          ListingModel(
        listingId:
            widget.listing.listingId,
        sellerId:
            widget.listing.sellerId,
        brandId:
            widget.listing.brandId,
        title:
            titleController.text.trim(),
        description:
            descriptionController.text.trim(),
        price: double.parse(
          priceController.text,
        ),
        images:
            widget.listing.images,
        deliveryAvailable:
            widget.listing.deliveryAvailable,
        pickupAvailable:
            widget.listing.pickupAvailable,
        category:
            widget.listing.category,
        status:
            widget.listing.status,
        createdAt:
            widget.listing.createdAt,
      );

      await ListingService()
          .updateListing(
        updated,
      );

      if (!mounted) return;

      context.pop(true);

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
        title:
            const Text(
          'Edit Listing',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [

            TextField(
              controller:
                  titleController,
              style: const TextStyle(
                color: Colors.white,
              ),
              cursorColor: Colors.white,
              decoration:
                  const InputDecoration(
                labelText:
                    'Title',
                labelStyle:
                    TextStyle(
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
                  descriptionController,
              maxLines: 5,
              style: const TextStyle(
                color: Colors.white,
              ),
              cursorColor: Colors.white,
              decoration:
                  const InputDecoration(
                labelText:
                    'Description',
                labelStyle:
                    TextStyle(
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
                  priceController,
              keyboardType:
                  TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
              ),
              cursorColor: Colors.white,
              decoration:
                  const InputDecoration(
                labelText:
                    'Price',
                labelStyle:
                    TextStyle(
                  color: Colors.white,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    isSaving
                        ? null
                        : saveChanges,
                child: Text(
                  isSaving
                      ? 'Saving...'
                      : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}