import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../models/message_model.dart';

class ChatService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<String> ensureChat({
    required String buyerId,
    required String sellerId,
    required String brandId,
    required String brandName,
    required String brandLogoUrl,
    String buyerName = 'Buyer',
    String listingId = '',
    String listingTitle = '',
  }) async {
    final ids = [buyerId, sellerId]..sort();
    final chatId = '${ids.first}_${ids.last}';

    await firestore.collection('chats').doc(chatId).set({
      'chatId': chatId,
      'participants': [buyerId, sellerId],
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'brandId': brandId,
      'brandName': brandName,
      'brandLogoUrl': brandLogoUrl,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final messageId = const Uuid().v4();
    final now = Timestamp.now();

    final message = MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      message: text,
      isRead: false,
      timestamp: now,
    );

    await firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set(message.toMap());
    await firestore.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastMessageSenderId': senderId,
      'lastMessageTime': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatId) {
    return firestore.collection('chats').doc(chatId).collection('messages').orderBy('timestamp').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getConversations(String userId) {
    return firestore.collection('chats').where('participants', arrayContains: userId).snapshots();
  }

  Future<void> markMessagesRead({required String chatId, required String userId}) async {
    final snapshot = await firestore.collection('chats').doc(chatId).collection('messages').where('receiverId', isEqualTo: userId).get();
    final unread = snapshot.docs.where((doc) => doc.data()['isRead'] != true);
    if (unread.isEmpty) return;
    final batch = firestore.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
