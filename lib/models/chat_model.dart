import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;

  final String buyerId;
  final String sellerId;

  final String lastMessage;

  final Timestamp lastMessageTime;

  ChatModel({
    required this.chatId,
    required this.buyerId,
    required this.sellerId,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory ChatModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      lastMessage:
          map['lastMessage'] ?? '',
      lastMessageTime:
          map['lastMessageTime'] ??
              Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime,
    };
  }
}