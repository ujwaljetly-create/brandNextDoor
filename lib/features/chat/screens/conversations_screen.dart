import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

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
          'Messages',
          style: TextStyle(
            color: _navy,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view messages.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ChatService().getConversations(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = [...?snapshot.data?.docs];
                docs.sort((a, b) {
                  final aTime = a.data()['lastMessageTime'] as Timestamp?;
                  final bTime = b.data()['lastMessageTime'] as Timestamp?;
                  return (bTime?.millisecondsSinceEpoch ?? 0)
                      .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No conversations yet. Open a product and tap Message Seller to start one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final isBuyer = data['buyerId'] == user.uid;
                    final peerId = isBuyer
                        ? (data['sellerId'] ?? '').toString()
                        : (data['buyerId'] ?? '').toString();
                    final peerName = isBuyer
                        ? (data['brandName'] ?? 'Seller').toString()
                        : (data['buyerName'] ?? 'Buyer').toString();
                    final logoUrl = isBuyer
                        ? (data['brandLogoUrl'] ?? '').toString()
                        : '';
                    final lastMessage =
                        (data['lastMessage'] ?? 'Start a conversation').toString();

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8D4B8),
                          backgroundImage:
                              logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                          child: logoUrl.isEmpty
                              ? Icon(
                                  isBuyer
                                      ? Icons.storefront_outlined
                                      : Icons.person_outline,
                                  color: _navy,
                                )
                              : null,
                        ),
                        title: Text(
                          peerName,
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: docs[index].id,
                                peerId: peerId,
                                peerName: peerName,
                                peerLogoUrl: logoUrl,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
