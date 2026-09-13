import 'package:cloud_firestore/cloud_firestore.dart';
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
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController cityController;
  late final TextEditingController dealPriceController;

  late bool deliveryAvailable;
  late bool pickupAvailable;
  late bool isHotDeal;
  DateTime? dealStartDate;
  DateTime? dealEndDate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.listing.title);
    descriptionController =
        TextEditingController(text: widget.listing.description);
    priceController = TextEditingController(
      text: widget.listing.price.toStringAsFixed(2),
    );
    cityController = TextEditingController(text: widget.listing.city);
    dealPriceController = TextEditingController(
      text: widget.listing.dealPrice > 0
          ? widget.listing.dealPrice.toStringAsFixed(2)
          : '',
    );

    deliveryAvailable = widget.listing.deliveryAvailable;
    pickupAvailable = widget.listing.pickupAvailable;
    isHotDeal = widget.listing.isHotDeal;
    dealStartDate = widget.listing.dealStartAt?.toDate();
    dealEndDate = widget.listing.dealEndAt?.toDate();
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

  Future<void> saveChanges() async {
    final price = double.tryParse(priceController.text.trim());
    final dealPrice = double.tryParse(dealPriceController.text.trim()) ?? 0;

    if (titleController.text.trim().isEmpty || price == null || price <= 0) {
      _message('Enter a title and valid price.');
      return;
    }

    if (cityController.text.trim().isEmpty) {
      _message('Enter the city for this listing.');
      return;
    }

    if (isHotDeal) {
      if (dealPrice <= 0 || dealPrice >= price) {
        _message('Deal price must be lower than the regular price.');
        return;
      }
      if (dealStartDate == null || dealEndDate == null) {
        _message('Choose start and end dates for the hot deal.');
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final updated = ListingModel(
        listingId: widget.listing.listingId,
        sellerId: widget.listing.sellerId,
        brandId: widget.listing.brandId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price: price,
        images: widget.listing.images,
        deliveryAvailable: deliveryAvailable,
        pickupAvailable: pickupAvailable,
        category: widget.listing.category,
        status: widget.listing.status,
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
        soldCount: widget.listing.soldCount,
        rating: widget.listing.rating,
        reviewCount: widget.listing.reviewCount,
        createdAt: widget.listing.createdAt,
      );

      await ListingService().updateListing(updated);

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      _message(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
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
      appBar: AppBar(title: const Text('Edit Listing')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Regular price',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: cityController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
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
                    subtitle: const Text('Show this listing in Hot deals near me.'),
                    value: isHotDeal,
                    onChanged: (value) {
                      setState(() {
                        isHotDeal = value;
                      });
                    },
                  ),
                  if (isHotDeal) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: dealPriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isSaving ? null : saveChanges,
              child: Text(isSaving ? 'Saving...' : 'Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
