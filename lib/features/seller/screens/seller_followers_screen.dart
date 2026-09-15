import 'package:flutter/material.dart';

import '../../brand/services/brand_service.dart';
import '../../buyer/services/follow_service.dart';

class SellerFollowersScreen extends StatefulWidget {
  const SellerFollowersScreen({super.key});

  @override
  State<SellerFollowersScreen> createState() => _SellerFollowersScreenState();
}

class _SellerFollowersScreenState extends State<SellerFollowersScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _cream = Color(0xFFF8F3EA);

  String brandId = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBrand();
  }

  Future<void> _loadBrand() async {
    try {
      final brand = await BrandService().getSellerBrand();
      brandId = (brand?['brandId'] ?? '').toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        title: const Text(
          'Followers',
          style: TextStyle(
            color: _navy,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : brandId.isEmpty
              ? const Center(child: Text('Create a brand to start building followers.'))
              : StreamBuilder(
                  stream: FollowService().watchFollowers(brandId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Text(
                            'No followers yet. Buyers who follow your store will appear here.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final data = docs[index].data();
                        final name = (data['displayName'] ?? '').toString().trim();
                        final email = (data['email'] ?? '').toString().trim();
                        final initial = name.isNotEmpty
                            ? name.substring(0, 1).toUpperCase()
                            : email.isNotEmpty
                                ? email.substring(0, 1).toUpperCase()
                                : 'B';
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE6DED2)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEAD8BA),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              name.isNotEmpty ? name : 'Buyer',
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: email.isEmpty ? null : Text(email),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
