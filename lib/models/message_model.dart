import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String chatId;

  final String senderId;
  final String receiverId;

  final String message;

  final bool isRead;

  final Timestamp timestamp;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.timestamp,
  });

  factory MessageModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return MessageModel(
      messageId:
          map['messageId'] ?? '',
      chatId:
          map['chatId'] ?? '',
      senderId:
          map['senderId'] ?? '',
      receiverId:
          map['receiverId'] ?? '',
      message:
          map['message'] ?? '',
      isRead:
          map['isRead'] ?? false,
      timestamp:
          map['timestamp'] ??
              Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'isRead': isRead,
      'timestamp': timestamp,
    };
  }
}