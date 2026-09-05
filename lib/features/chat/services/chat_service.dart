import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../models/message_model.dart';

class ChatService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final messageId =
        const Uuid().v4();

    final message = MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      message: text,
      isRead: false,
      timestamp: Timestamp.now(),
    );

    await firestore
        .collection('messages')
        .doc(messageId)
        .set(
          message.toMap(),
        );

    await firestore
        .collection('chats')
        .doc(chatId)
        .update({
      'lastMessage': text,
      'lastMessageTime':
          Timestamp.now(),
    });
  }

  Stream<QuerySnapshot>
      getMessages(
    String chatId,
  ) {
    return firestore
        .collection('messages')
        .where(
          'chatId',
          isEqualTo: chatId,
        )
        .orderBy('timestamp')
        .snapshots();
  }
}