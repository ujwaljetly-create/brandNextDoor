import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../brand/services/brand_service.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../listings/services/listing_service.dart';
import '../../reviews/services/review_service.dart';
import '../../reviews/widgets/reviews_preview.dart';
import '../services/follow_service.dart';
import '../widgets/product_card.dart';

class SellerStorefrontScreen extends StatefulWidget {
  final String sellerId;
  final String brandId;
  const SellerStorefrontScreen({super.key, required this.sellerId, required this.brandId});
  @override
  State<SellerStorefrontScreen> createState() => _SellerStorefrontScreenState();
}

class _SellerStorefrontScreenState extends State<SellerStorefrontScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);
  bool isLoading = true, followBusy = false, openingChat = false;
  Map<String, dynamic>? brand;

  @override
  void initState() { super.initState(); _loadBrand(); }

  Future<void> _loadBrand() async {
    try { brand = widget.brandId.isNotEmpty ? await BrandService().getBrand(widget.brandId) : null; }
    finally { if (mounted) setState(() => isLoading = false); }
  }

  Future<void> _toggleFollow(bool following) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { _message('Please sign in to follow sellers.'); return; }
    if (user.uid == widget.sellerId) { _message('You cannot follow your own store.'); return; }
    if (followBusy) return;
    setState(() => followBusy = true);
    try {
      if (following) {
        await FollowService().unfollow(widget.brandId);
        if (mounted) _message('You have unfollowed this seller.');
      } else {
        await FollowService().follow(brandId: widget.brandId, sellerId: widget.sellerId, brandName: (brand?['brandName'] ?? 'Seller').toString(), brandLogoUrl: (brand?['logoUrl'] ?? '').toString());
        if (mounted) _message('Now you will get updates from this seller.');
      }
    } catch (e) { if (mounted) _message('Could not update follow status: $e'); }
    finally { if (mounted) setState(() => followBusy = false); }
  }

  Future<void> _openChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { _message('Please sign in to message the seller.'); return; }
    if (user.uid == widget.sellerId) { _message('This is your own store.'); return; }
    if (openingChat) return;
    setState(() => openingChat = true);
    try {
      final name = (brand?['brandName'] ?? 'Seller').toString();
      final logo = (brand?['logoUrl'] ?? '').toString();
      final chatId = await ChatService().ensureChat(buyerId: user.uid, sellerId: widget.sellerId, brandId: widget.brandId, brandName: name, brandLogoUrl: logo);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, peerId: widget.sellerId, peerName: name, peerLogoUrl: logo)));
    } catch (e) { if (mounted) _message('Could not open chat: $e'); }
    finally { if (mounted) setState(() => openingChat = false); }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final name = (brand?['brandName'] ?? '').toString().trim();
    final tagline = (brand?['tagline'] ?? '').toString().trim();
    final description = (brand?['description'] ?? '').toString().trim();
    final logo = (brand?['logoUrl'] ?? '').toString().trim();
    final city = (brand?['city'] ?? '').toString().trim();
    final rating = ((brand?['rating'] ?? 0) as num).toDouble();
    final reviews = ((brand?['totalReviews'] ?? 0) as num).toInt();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        elevation: 0,
        leading: IconButton(onPressed: () => context.canPop() ? context.pop() : context.go('/buyer-home'), icon: const Icon(Icons.arrow_back, color: _navy)),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : StreamBuilder<List<ListingModel>>(
        stream: ListingService().getActiveSellerListings(widget.sellerId),
        builder: (context, snapshot) {
          final listings = snapshot.data ?? const <ListingModel>[];
          return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
            Center(child: Container(
              width: 150, height: 150, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFE5D8C7)), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 14, offset: Offset(0, 5))]),
              child: logo.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.storefront_outlined, color: _navy, size: 58))) : const Icon(Icons.storefront_outlined, color: _navy, size: 58),
            )),
            const SizedBox(height: 18),
            Text(name.isEmpty ? 'Local Seller' : name, textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.w700)),
            if (city.isNotEmpty) ...[const SizedBox(height: 7), Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.location_on_outlined, size: 16, color: _gold), const SizedBox(width: 4), Text(city, style: const TextStyle(color: _navy))])],
            if (description.isNotEmpty || tagline.isNotEmpty) ...[const SizedBox(height: 14), Text(description.isNotEmpty ? description : tagline, textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontSize: 15, height: 1.45))],
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_metric(rating > 0 ? rating.toStringAsFixed(1) : 'New', 'Rating'), _metric(reviews.toString(), 'Reviews'), _metric(listings.length.toString(), 'Products')]),
            const SizedBox(height: 20),
            StreamBuilder<bool>(stream: FollowService().watchFollowing(widget.brandId), initialData: false, builder: (context, snap) {
              final following = snap.data ?? false;
              return Row(children: [
                Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)), onPressed: followBusy ? null : () => _toggleFollow(following), icon: Icon(following ? Icons.person_remove_alt_1_outlined : Icons.person_add_alt_1_outlined), label: Text(following ? 'Unfollow' : 'Follow'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)), onPressed: openingChat ? null : _openChat, icon: const Icon(Icons.chat_bubble_outline), label: const Text('Message'))),
              ]);
            }),
            const SizedBox(height: 28),
            const Row(children: [Expanded(child: _StoreTab('Products', true)), Expanded(child: _StoreTab('About', false)), Expanded(child: _StoreTab('Reviews', false))]),
            const SizedBox(height: 18),
            if (listings.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No active products right now.'))) else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: listings.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .68, crossAxisSpacing: 12, mainAxisSpacing: 12), itemBuilder: (_, i) => ProductCard(listing: listings[i])),
            const SizedBox(height: 22),
            ReviewsPreview(title: 'Reviews', reviews: ReviewService().getSellerReviews(widget.sellerId), sellerRating: true),
          ]);
        },
      ),
    );
  }

  Widget _metric(String value, String label) => Column(children: [Text(value, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 20)), const SizedBox(height: 2), Text(label, style: const TextStyle(color: Color(0xFF7A858B), fontSize: 12))]);
}

class _StoreTab extends StatelessWidget {
  final String label; final bool active;
  const _StoreTab(this.label, this.active);
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: TextStyle(color: const Color(0xFF0C2430), fontWeight: active ? FontWeight.w800 : FontWeight.w500)), const SizedBox(height: 8), Container(height: 2, color: active ? const Color(0xFFC99245) : Colors.transparent)]);
}
