import 'package:flutter/material.dart';

import '../../../models/order_model.dart';
import '../services/order_service.dart';

class SellerOrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const SellerOrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<SellerOrderDetailsScreen> createState() =>
      _SellerOrderDetailsScreenState();
}

class _SellerOrderDetailsScreenState
    extends State<SellerOrderDetailsScreen> {
  bool isUpdating = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      isUpdating = true;
    });

    try {
      await action();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() {
        isUpdating = false;
      });
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject order'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Tell the buyer why this order cannot be accepted.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('Reject Order'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null || reason.isEmpty) return;

    await _run(
      () => OrderService().rejectOrder(
        orderId: widget.order.orderId,
        reason: reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final date = order.createdAt.toDate().toLocal();
    final received =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (order.productImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                order.productImageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            order.productTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _detailRow('Buyer',
                      order.buyerName.isNotEmpty ? order.buyerName : 'Buyer'),
                  _detailRow('Quantity', order.quantity.toString()),
                  _detailRow('Received', received),
                  _detailRow('Fulfillment',
                      order.fulfillmentMethod == 'delivery'
                          ? 'Delivery'
                          : 'Pickup'),
                  _detailRow('Status', order.statusLabel),
                  _detailRow(
                    'Unit price',
                    '\$${order.unitPrice.toStringAsFixed(2)}',
                  ),
                  _detailRow(
                    'Total earnings',
                    '\$${order.amount.toStringAsFixed(2)}',
                    emphasize: true,
                  ),
                  if (order.rejectionReason.isNotEmpty)
                    _detailRow('Rejection reason', order.rejectionReason),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (order.status == 'pending') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating
                    ? null
                    : () => _run(
                          () => OrderService().acceptOrder(order.orderId),
                        ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Accept Order'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isUpdating ? null : _reject,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Reject Order'),
              ),
            ),
          ],
          if (order.status == 'accepted' &&
              order.fulfillmentMethod == 'pickup')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating
                    ? null
                    : () => _run(
                          () => OrderService()
                              .markReadyForPickup(order.orderId),
                        ),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Mark Ready for Pickup'),
              ),
            ),
          if (order.status == 'accepted' &&
              order.fulfillmentMethod == 'delivery')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating
                    ? null
                    : () => _run(
                          () => OrderService()
                              .markOutForDelivery(order.orderId),
                        ),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Mark Out for Delivery'),
              ),
            ),
          if (order.status == 'ready_for_pickup' ||
              order.status == 'out_for_delivery')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating
                    ? null
                    : () => _run(
                          () => OrderService().markDelivered(order.orderId),
                        ),
                icon: const Icon(Icons.done_all),
                label: const Text('Mark Delivered'),
              ),
            ),
          if (isUpdating) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
                fontSize: emphasize ? 18 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
