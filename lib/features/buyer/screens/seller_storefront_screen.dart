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

  const SellerStorefrontScreen({
    super.key,
    required this.sellerId,
    required this.brandId,
  });

  @override
  State<SellerStorefrontScreen> createState() => _SellerStorefrontScreenState();
}

class _SellerStorefrontScreenState extends State<SellerStorefrontScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  bool isLoading = true;
  bool followBusy = false;
  bool openingChat = false;
  Map<String, dynamic>? brand;

  @override
  void initState() {
    super.initState();
    _loadBrand();
  }

  Future<void> _loadBrand() async {
    try {
      final result = widget.brandId.isNotEmpty
          ? await BrandService().getBrand(widget.brandId)
          : null;
      if (!mounted) return;
      setState(() {
        brand = result;
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow(bool following) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Please sign in to follow sellers.');
      return;
    }
    if (user.uid == widget.sellerId) {
      _message('You cannot follow your own store.');
      return;
    }
    if (followBusy) return;
    setState(() => followBusy = true);
    try {
      if (following) {
        await FollowService().unfollow(widget.brandId);
        if (mounted) _message('You have unfollowed this seller.');
      } else {
        await FollowService().follow(
          brandId: widget.brandId,
          sellerId: widget.sellerId,
          brandName: (brand?['brandName'] ?? 'Seller').toString(),
          brandLogoUrl: (brand?['logoUrl'] ?? '').toString(),
        );
        if (mounted) {
          _message('Now you will get updates from this seller.');
        }
      }
    } catch (e) {
      if (mounted) _message('Could not update follow status: $e');
    } finally {
      if (mounted) setState(() => followBusy = false);
    }
  }

  Future<void> _openChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Please sign in to message the seller.');
      return;
    }
    if (user.uid == widget.sellerId) {
      _message('This is your own store.');
      return;
    }
    if (openingChat) return;
    setState(() => openingChat = true);
    try {
      final brandName = (brand?['brandName'] ?? 'Seller').toString();
      final logoUrl = (brand?['logoUrl'] ?? '').toString();
      final chatId = await ChatService().ensureChat(
        buyerId: user.uid,
        sellerId: widget.sellerId,
        brandId: widget.brandId,
        brandName: brandName,
        brandLogoUrl: logoUrl,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            peerId: widget.sellerId,
            peerName: brandName,
            peerLogoUrl: logoUrl,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _message('Could not open chat: $e');
    } finally {
      if (mounted) setState(() => openingChat = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final brandName = (brand?['brandName'] ?? '').toString().trim();
    final tagline = (brand?['tagline'] ?? '').toString().trim();
    final description = (brand?['description'] ?? '').toString().trim();
    final logoUrl = (brand?['logoUrl'] ?? '').toString().trim();
    final bannerUrl = (brand?['bannerUrl'] ?? '').toString().trim();
    final city = (brand?['city'] ?? '').toString().trim();
    final rating = ((brand?['rating'] ?? 0) as num).toDouble();
    final reviews = ((brand?['totalReviews'] ?? 0) as num).toInt();

    return Scaffold(
      backgroundColor: _cream,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ListingModel>>(
              stream: ListingService().getActiveSellerListings(widget.sellerId),
              builder: (context, snapshot) {
                final listings = snapshot.data ?? const <ListingModel>[];
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 170,
                      backgroundColor: _navy,
                      leading: IconButton(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/buyer-home'),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: bannerUrl.isNotEmpty
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    bannerUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _bannerFallback(),
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: .18),
                                  ),
                                ],
                              )
                            : _bannerFallback(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                        child: Column(
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -34),
                              child: Container(
                                width: 96,
                                height: 96,
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFE5D8C7),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: logoUrl.isNotEmpty
                                    ? Image.network(
                                        logoUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.storefront_outlined,
                                          color: _navy,
                                          size: 42,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.storefront_outlined,
                                        color: _navy,
                                        size: 42,
                                      ),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -20),
                              child: Column(
                                children: [
                                  Text(
                                    brandName.isEmpty ? 'Local Seller' : brandName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _navy,
                                      fontFamily: 'serif',
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (city.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(city),
                                      ],
                                    ),
                                  ],
                                  if (description.isNotEmpty || tagline.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      description.isNotEmpty ? description : tagline,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _navy,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _metric(
                                        rating > 0 ? rating.toStringAsFixed(1) : 'New',
                                        'Rating',
                                      ),
                                      _metric(reviews.toString(), 'Reviews'),
                                      _metric(listings.length.toString(), 'Products'),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  StreamBuilder<bool>(
                                    stream: FollowService().watchFollowing(widget.brandId),
                                    initialData: false,
                                    builder: (context, followSnapshot) {
                                      final following = followSnapshot.data ?? false;
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.icon(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: _navy,
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size.fromHeight(48),
                                              ),
                                              onPressed: followBusy
                                                  ? null
                                                  : () => _toggleFollow(following),
                                              icon: Icon(
                                                following
                                                    ? Icons.person_remove_alt_1_outlined
                                                    : Icons.person_add_alt_1_outlined,
                                              ),
                                              label: Text(
                                                following ? 'Unfollow' : 'Follow',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: FilledButton.icon(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: _navy,
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size.fromHeight(48),
                                              ),
                                              onPressed:
                                                  openingChat ? null : _openChat,
                                              icon: const Icon(
                                                Icons.chat_bubble_outline,
                                              ),
                                              label: const Text('Message'),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Expanded(child: _StoreTab('Products', true)),
                                Expanded(child: _StoreTab('About', false)),
                                Expanded(child: _StoreTab('Reviews', false)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (listings.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(30),
                                child: Text('No active products right now.'),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: listings.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: .68,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemBuilder: (_, i) =>
                                    ProductCard(listing: listings[i]),
                              ),
                            const SizedBox(height: 22),
                            ReviewsPreview(
                              title: 'Reviews',
                              reviews: ReviewService()
                                  .getSellerReviews(widget.sellerId),
                              sellerRating: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _bannerFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C2430), Color(0xFF6E5336)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.storefront_outlined,
            color: Color(0xFFC99245),
            size: 58,
          ),
        ),
      );

  Widget _metric(String value, String label) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A858B),
              fontSize: 11,
            ),
          ),
        ],
      );
}

class _StoreTab extends StatelessWidget {
  final String label;
  final bool active;

  const _StoreTab(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          color: active ? const Color(0xFFC99245) : Colors.transparent,
        ),
      ],
    );
  }
}
