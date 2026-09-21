import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';

class BuyerNotificationsScreen extends StatelessWidget {
  const BuyerNotificationsScreen({super.key});

  static const _navy = Color(0xFF0C2430);
  static const _cream = Color(0xFFF8F3EA);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: _navy,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view notifications.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = [...?snapshot.data?.docs];
                docs.sort((a, b) {
                  final aTime = a.data()['createdAt'] as Timestamp?;
                  final bTime = b.data()['createdAt'] as Timestamp?;
                  return (bTime?.millisecondsSinceEpoch ?? 0)
                      .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'You do not have any notifications yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final read = data['read'] == true;
                    final title = (data['title'] ?? 'Notification').toString();
                    final body = (data['body'] ?? '').toString();
                    final createdAt = data['createdAt'] as Timestamp?;
                    final type = (data['type'] ?? '').toString();

                    return Material(
                      color: read ? Colors.white : const Color(0xFFFFF7E9),
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8D4B8),
                          child: Icon(
                            _iconFor(type),
                            color: _navy,
                          ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            color: _navy,
                            fontWeight: read ? FontWeight.w600 : FontWeight.w800,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(body),
                            ],
                            if (createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _formatTime(createdAt.toDate()),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                        onTap: () async {
                          if (!read) {
                            await doc.reference.update({'read': true});
                          }
                          if (!context.mounted) return;
                          await _openNotification(context, data);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final type = (data['type'] ?? '').toString();
    final listingId = (data['listingId'] ?? '').toString();

    if ((type == 'seller_new_listing' || type == 'seller_new_deal') &&
        listingId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .get();
      if (!doc.exists || !context.mounted) return;
      context.push('/listing-details', extra: ListingModel.fromMap(doc.data()!));
      return;
    }

    if (type == 'chat_message') {
      context.push('/messages');
      return;
    }

    if (type == 'order_status') {
      context.push('/buyer-orders');
    }
  }

  IconData _iconFor(String type) {
    if (type == 'seller_new_deal') return Icons.local_offer_outlined;
    if (type == 'seller_new_listing') return Icons.storefront_outlined;
    if (type == 'chat_message') return Icons.chat_bubble_outline;
    if (type == 'order_status') return Icons.receipt_long_outlined;
    return Icons.notifications_none;
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day  $hour:$minute';
  }
}
