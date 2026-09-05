import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/listing_model.dart';
import '../../listings/services/listing_service.dart';

final buyerListingsProvider =
    StreamProvider<List<ListingModel>>(
  (ref) {
    return ListingService()
        .getActiveListings();
  },
);