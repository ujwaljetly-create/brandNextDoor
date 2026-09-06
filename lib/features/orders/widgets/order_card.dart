import 'package:flutter/material.dart';

import '../../../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool showSellerInfo;
  final VoidCallback? onTap;
  final VoidCallback? onSellerTap;
  final Widget? action;
  final String? sellerNameOverride;
  final String? sellerLogoUrlOverride;

  const OrderCard({
    super.key,
    required this.order,
    this.showSellerInfo = false,
    this.onTap,
    this.onSellerTap,
    this.action,
    this.sellerNameOverride,
    this.sellerLogoUrlOverride,
  });

  @override
  Widget build(BuildContext context) {
    final sellerName = (sellerNameOverride ?? order.sellerName).trim();
    final sellerLogoUrl =
        (sellerLogoUrlOverride ?? order.sellerLogoUrl).trim();

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
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onSellerTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: sellerLogoUrl.isNotEmpty
                              ? NetworkImage(sellerLogoUrl)
                              : null,
                          child: sellerLogoUrl.isEmpty
                              ? const Icon(Icons.storefront, size: 21)
                              : null,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sellerName.isNotEmpty ? sellerName : 'Seller',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (onSellerTap != null)
                                Text(
                                  'View seller and listings',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        if (onSellerTap != null)
                          const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ],
              if (order.status == 'rejected' &&
                  order.rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Reason: ${order.rejectionReason}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
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
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, size: 34),
    );
  }

  Widget _statusChip(BuildContext context) {
    Color color;
    switch (order.status) {
      case 'delivered':
        color = Colors.green.shade700;
        break;
      case 'rejected':
      case 'cancelled':
        color = Theme.of(context).colorScheme.error;
        break;
      case 'accepted':
      case 'ready_for_pickup':
      case 'out_for_delivery':
        color = Colors.blue.shade700;
        break;
      default:
        color = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
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
