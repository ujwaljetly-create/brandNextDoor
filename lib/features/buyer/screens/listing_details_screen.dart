import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/listing_model.dart';
import '../../brand/services/brand_service.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../reviews/services/review_service.dart';
import '../../reviews/widgets/reviews_preview.dart';
import '../services/saved_items_service.dart';
import '../widgets/brand_info_card.dart';
import '../widgets/listing_image_section.dart';

class ListingDetailsScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailsScreen({super.key, required this.listing});

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  bool isSaved = false;
  bool isSaving = false;
  bool isOpeningChat = false;

  ListingModel get listing => widget.listing;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final value = await SavedItemsService().isSaved(
        uid: user.uid,
        listingId: listing.listingId,
      );
      if (mounted) setState(() => isSaved = value);
    } catch (_) {}
  }

  Future<void> _toggleSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Please sign in to save items.');
      return;
    }
    if (isSaving) return;
    setState(() => isSaving = true);
    try {
      final saved = await SavedItemsService().toggle(
        uid: user.uid,
        listing: listing,
      );
      if (!mounted) return;
      setState(() => isSaved = saved);
      _message(saved ? 'Saved to your items.' : 'Removed from saved items.');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  String get _shareLink =>
      'https://brandnextdoor.app/listing/${listing.listingId}';

  String get _shareText =>
      '${listing.title} - \$${listing.currentPrice.toStringAsFixed(2)} on Brand Next Door\n$_shareLink';

  Future<void> _showShareOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share this item',
                style: TextStyle(
                  color: _navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.link, color: _navy),
                title: const Text('Copy link'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: _shareLink));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (mounted) _message('Link copied.');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: _gold),
                title: const Text('Share via WhatsApp or other apps'),
                subtitle: const Text('Choose WhatsApp, Messages, email, or another installed app.'),
                onTap: () async {
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  await Share.share(_shareText, subject: listing.title);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _messageSeller() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Please sign in to message the seller.');
      return;
    }
    if (user.uid == listing.sellerId) {
      _message('This is your own listing.');
      return;
    }
    if (isOpeningChat) return;

    setState(() => isOpeningChat = true);
    try {
      final brand = listing.brandId.isNotEmpty
          ? await BrandService().getBrand(listing.brandId)
          : null;
      final brandName = (brand?['brandName'] ?? 'Seller').toString();
      final brandLogoUrl = (brand?['logoUrl'] ?? '').toString();

      final chatId = await ChatService().ensureChat(
        buyerId: user.uid,
        sellerId: listing.sellerId,
        brandId: listing.brandId,
        brandName: brandName,
        brandLogoUrl: brandLogoUrl,
        listingId: listing.listingId,
        listingTitle: listing.title,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            peerId: listing.sellerId,
            peerName: brandName,
            peerLogoUrl: brandLogoUrl,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _message('Could not open chat: $e');
    } finally {
      if (mounted) setState(() => isOpeningChat = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: _navy),
        ),
        actions: [
          IconButton(
            onPressed: _showShareOptions,
            icon: const Icon(Icons.share_outlined, color: _navy),
          ),
          IconButton(
            onPressed: isSaving ? null : _toggleSaved,
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? _gold : _navy,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          ListingImageSection(images: listing.images),
          const SizedBox(height: 18),
          BrandInfoCard(
            brandId: listing.brandId,
            sellerId: listing.sellerId,
            currentListingId: listing.listingId,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        color: _navy,
                        fontFamily: 'serif',
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (listing.rating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 17, color: _gold),
                          const SizedBox(width: 4),
                          Text('${listing.rating.toStringAsFixed(1)} (${listing.reviewCount} reviews)'),
                        ],
                      )
                    else
                      const Text('New local find'),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '\$${listing.currentPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (listing.city.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.location_on_outlined, size: 16),
                  label: Text(listing.city),
                  backgroundColor: Colors.white,
                ),
              if (listing.pickupAvailable)
                const Chip(
                  avatar: Icon(Icons.storefront_outlined, size: 16),
                  label: Text('Local pickup'),
                  backgroundColor: Colors.white,
                ),
              if (listing.deliveryAvailable)
                const Chip(
                  avatar: Icon(Icons.local_shipping_outlined, size: 16),
                  label: Text('Delivery available'),
                  backgroundColor: Colors.white,
                ),
              if (listing.hasActiveDeal)
                Chip(
                  avatar: const Icon(Icons.local_offer_outlined, size: 16),
                  label: Text('${listing.discountPercent}% off'),
                  backgroundColor: const Color(0xFFF3E1C3),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _card(
            title: 'About this product',
            child: Text(
              listing.description,
              style: const TextStyle(color: _navy, height: 1.55),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'Local shopping details',
            child: Column(
              children: [
                _detailRow(
                  Icons.location_on_outlined,
                  listing.city.isEmpty ? 'Nearby' : listing.city,
                ),
                if (listing.pickupAvailable)
                  _detailRow(Icons.storefront_outlined, 'Available for pickup today'),
                if (listing.deliveryAvailable)
                  _detailRow(Icons.local_shipping_outlined, 'Local delivery available'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ReviewsPreview(
            title: 'Reviews',
            reviews: ReviewService().getListingReviews(listing.listingId),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/place-order', extra: listing),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isOpeningChat ? null : _messageSeller,
                  icon: isOpeningChat
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message Seller'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _navy),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: _navy))),
        ],
      ),
    );
  }
}
