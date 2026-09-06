import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../brand/services/brand_service.dart';
import '../../brand/widgets/brand_status_card.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/recent_order_card.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({
    super.key,
  });

  @override
  State<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState
    extends State<SellerDashboardScreen> {
  bool isLoading = true;
  bool brandExists = false;
  String brandName = '';
  String tagline = '';
  String logoUrl = '';
  int completion = 0;

  @override
  void initState() {
    super.initState();
    loadBrand();
  }

  Future<void> loadBrand() async {
    try {
      final brand = await BrandService().getSellerBrand();

      if (brand != null) {
        brandExists = true;
        brandName = brand['brandName'] ?? '';
        tagline = brand['tagline'] ?? '';
        logoUrl = brand['logoUrl'] ?? '';
        completion = 0;

        if (brandName.isNotEmpty) {
          completion += 25;
        }

        if (tagline.isNotEmpty) {
          completion += 25;
        }

        if ((brand['description'] ?? '')
            .toString()
            .isNotEmpty) {
          completion += 25;
        }

        if (logoUrl.isNotEmpty) {
          completion += 25;
        }
      }
    } catch (e) {
      debugPrint('Load Brand Error: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              context.push('/settings?role=seller');
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadBrand,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage your brand and grow your business',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              BrandStatusCard(
                brandExists: brandExists,
                brandName: brandName,
                tagline: tagline,
                logoUrl: logoUrl,
                completion: completion,
                onPressed: () {
                  if (!brandExists) {
                    context.push('/seller-onboarding');
                  } else {
                    context.push('/seller-brand');
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/create-listing');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/my-listings');
                      },
                      icon: const Icon(Icons.inventory),
                      label: const Text('My Listings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: const [
                  DashboardStatCard(
                    title: 'Orders',
                    value: '0',
                    icon: Icons.shopping_bag,
                  ),
                  DashboardStatCard(
                    title: 'Sales',
                    value: '\$0',
                    icon: Icons.attach_money,
                  ),
                  DashboardStatCard(
                    title: 'Listings',
                    value: '0',
                    icon: Icons.inventory,
                  ),
                  DashboardStatCard(
                    title: 'Messages',
                    value: '0',
                    icon: Icons.chat_bubble,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (!brandExists)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.05,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Create your brand to start receiving orders.',
                  ),
                )
              else ...[
                const RecentOrderCard(
                  customerName: 'John Smith',
                  itemName: 'Handmade Candle',
                  amount: '\$35',
                ),
                const SizedBox(height: 12),
                const RecentOrderCard(
                  customerName: 'Sarah Lee',
                  itemName: 'Gift Box',
                  amount: '\$75',
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
