import 'package:flutter/material.dart';

import '../../../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool showSellerInfo;
  final VoidCallback? onTap;
  final Widget? action;

  const OrderCard({
    super.key,
    required this.order,
    this.showSellerInfo = false,
    this.onTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: order.productImageUrl.isNotEmpty
                        ? Image.network(
                            order.productImageUrl,
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Quantity: ${order.quantity}'),
                        const SizedBox(height: 6),
                        _statusChip(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${order.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (showSellerInfo) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundImage: order.sellerLogoUrl.isNotEmpty
                          ? NetworkImage(order.sellerLogoUrl)
                          : null,
                      child: order.sellerLogoUrl.isEmpty
                          ? const Icon(Icons.storefront, size: 19)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        order.sellerName.isNotEmpty
                            ? order.sellerName
                            : 'Seller',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (order.status == 'rejected' &&
                  order.rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Reason: ${order.rejectionReason}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 14),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 82,
      height: 82,
      color: const Color(0xFF36445E),
      child: const Icon(Icons.image_outlined, size: 34),
    );
  }

  Widget _statusChip(BuildContext context) {
    Color color;
    switch (order.status) {
      case 'delivered':
        color = Colors.green;
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.redAccent;
        break;
      case 'accepted':
      case 'ready_for_pickup':
      case 'out_for_delivery':
        color = Colors.lightBlueAccent;
        break;
      default:
        color = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
