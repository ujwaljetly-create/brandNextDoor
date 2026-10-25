import 'package:flutter/material.dart';

import '../../../models/listing_model.dart';
import '../../buyer/screens/listing_details_screen.dart';

/// Legacy compatibility wrapper.
///
/// The buyer module now uses [ListingDetailsScreen] as the single product
/// details experience. Keeping this wrapper prevents older imports/routes from
/// breaking while ensuring they render the current buyer UI and functionality.
class ProductDetailsScreen extends StatelessWidget {
  final ListingModel listing;

  const ProductDetailsScreen({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return ListingDetailsScreen(listing: listing);
  }
}
