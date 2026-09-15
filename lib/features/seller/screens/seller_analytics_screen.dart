import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../../listings/services/listing_service.dart';
import '../../orders/services/order_service.dart';

class SellerAnalyticsScreen extends StatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  int _days = 30;
  int? _selectedPoint;

  DateTime _orderDate(OrderModel order) =>
      (order.completedAt ?? order.updatedAt ?? order.createdAt).toDate();

  List<OrderModel> _periodOrders(List<OrderModel> orders) {
    final cutoff = DateTime.now().subtract(Duration(days: _days));
    return orders
        .where((o) => o.status == 'delivered' && _orderDate(o).isAfter(cutoff))
        .toList();
  }

  List<_SalesPoint> _salesPoints(List<OrderModel> delivered) {
    final now = DateTime.now();
    final bucketCount = _days == 7 ? 7 : (_days == 30 ? 10 : 12);
    final bucketDays = (_days / bucketCount).ceil();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: _days - 1));

    return List.generate(bucketCount, (index) {
      final bucketStart = start.add(Duration(days: index * bucketDays));
      final bucketEnd = index == bucketCount - 1
          ? now.add(const Duration(days: 1))
          : bucketStart.add(Duration(days: bucketDays));
      final value = delivered
          .where((o) {
            final date = _orderDate(o);
            return !date.isBefore(bucketStart) && date.isBefore(bucketEnd);
          })
          .fold<double>(0, (sum, o) => sum + o.amount);
      return _SalesPoint(date: bucketStart, value: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view insights.')),
      );
    }

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/seller-dashboard'),
          icon: const Icon(Icons.arrow_back, color: _navy),
        ),
        title: const Text(
          'Insights',
          style: TextStyle(
            color: _navy,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().getSellerOrders(user.uid),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting &&
              !orderSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = orderSnapshot.data ?? const <OrderModel>[];
          final delivered = _periodOrders(orders);
          final totalSales = delivered.fold<double>(0, (sum, o) => sum + o.amount);
          final totalUnits = delivered.fold<int>(0, (sum, o) => sum + o.quantity);
          final averageOrderValue =
              delivered.isEmpty ? 0.0 : totalSales / delivered.length;
          final points = _salesPoints(delivered);

          return StreamBuilder<List<ListingModel>>(
            stream: ListingService().getSellerListings(user.uid),
            builder: (context, listingSnapshot) {
              final listings = listingSnapshot.data ?? const <ListingModel>[];
              final topProducts = [...listings]
                ..sort((a, b) => b.soldCount.compareTo(a.soldCount));

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Last $_days days',
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE4DDD2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _days,
                            icon: const Icon(Icons.keyboard_arrow_down, color: _navy),
                            style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            items: const [
                              DropdownMenuItem(value: 7, child: Text('7 days')),
                              DropdownMenuItem(value: 30, child: Text('30 days')),
                              DropdownMenuItem(value: 90, child: Text('90 days')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _days = value;
                                _selectedPoint = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.25,
                    children: [
                      _MetricCard(title: 'Total Sales', value: '\$${totalSales.toStringAsFixed(2)}', icon: Icons.attach_money),
                      _MetricCard(title: 'Orders', value: delivered.length.toString(), icon: Icons.receipt_long_outlined),
                      _MetricCard(title: 'Units Sold', value: totalUnits.toString(), icon: Icons.shopping_bag_outlined),
                      _MetricCard(title: 'Avg. Order', value: '\$${averageOrderValue.toStringAsFixed(2)}', icon: Icons.trending_up),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE6DED2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sales Performance',
                          style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Delivered order revenue',
                          style: TextStyle(color: Color(0xFF7A858B), fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        if (delivered.isEmpty)
                          Container(
                            height: 180,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _cream,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.show_chart, color: Color(0xFF9AA3A8), size: 34),
                                SizedBox(height: 8),
                                Text(
                                  'No sales data for this period yet.',
                                  style: TextStyle(color: Color(0xFF6D787E), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          if (_selectedPoint != null && _selectedPoint! < points.length)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${_dateLabel(points[_selectedPoint!].date)}  •  \$${points[_selectedPoint!].value.toStringAsFixed(2)}',
                                style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
                              ),
                            ),
                          SizedBox(
                            height: 190,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) {
                                    final width = constraints.maxWidth;
                                    final usable = math.max(1.0, width - 24);
                                    final x = (details.localPosition.dx - 12).clamp(0.0, usable);
                                    final index = points.length == 1
                                        ? 0
                                        : ((x / usable) * (points.length - 1)).round();
                                    setState(() => _selectedPoint = index.clamp(0, points.length - 1));
                                  },
                                  child: CustomPaint(
                                    painter: _SalesTrendPainter(
                                      points: points,
                                      selectedIndex: _selectedPoint,
                                      lineColor: _gold,
                                      axisColor: const Color(0xFFE5DDD2),
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the trend line to inspect a period.',
                            style: TextStyle(color: Color(0xFF7A858B), fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Top Products', style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (topProducts.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No product data available yet.')))
                  else
                    ...topProducts.take(5).map((listing) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE6DED2))),
                      child: Row(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 58, height: 58, child: listing.images.isNotEmpty ? Image.network(listing.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined)) : const Icon(Icons.image_outlined))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('${listing.soldCount} sold', style: const TextStyle(color: Color(0xFF6D787E), fontSize: 12))])),
                        Text('\$${listing.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)),
                      ]),
                    )),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/seller-dashboard');
          if (index == 1) context.push('/seller-orders');
          if (index == 2) context.push('/messages');
          if (index == 3) context.push('/settings?role=seller');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) => '${date.month}/${date.day}';
}

class _SalesPoint {
  final DateTime date;
  final double value;
  const _SalesPoint({required this.date, required this.value});
}

class _SalesTrendPainter extends CustomPainter {
  final List<_SalesPoint> points;
  final int? selectedIndex;
  final Color lineColor;
  final Color axisColor;

  const _SalesTrendPainter({
    required this.points,
    required this.selectedIndex,
    required this.lineColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 12.0, right = 12.0, top = 12.0, bottom = 22.0;
    final width = math.max(1.0, size.width - left - right);
    final height = math.max(1.0, size.height - top - bottom);
    final maxValue = math.max(1.0, points.map((p) => p.value).reduce(math.max));

    final gridPaint = Paint()..color = axisColor..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + height * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), gridPaint);
    }

    Offset pointOffset(int i) {
      final x = points.length == 1 ? left + width / 2 : left + width * i / (points.length - 1);
      final y = top + height - (points[i].value / maxValue) * height;
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = pointOffset(i);
      if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(pointOffset(points.length - 1).dx, top + height)
      ..lineTo(pointOffset(0).dx, top + height)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = lineColor.withValues(alpha: .10));
    canvas.drawPath(path, Paint()..color = lineColor..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    for (var i = 0; i < points.length; i++) {
      final p = pointOffset(i);
      final selected = i == selectedIndex;
      canvas.drawCircle(p, selected ? 6 : 3.5, Paint()..color = selected ? const Color(0xFF0C2430) : lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.selectedIndex != selectedIndex;
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _MetricCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6DED2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _SellerAnalyticsScreenState._gold, size: 22),
        const Spacer(),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _SellerAnalyticsScreenState._navy, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Color(0xFF6D787E), fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
