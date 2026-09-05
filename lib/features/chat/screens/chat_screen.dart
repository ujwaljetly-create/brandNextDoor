import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen
    extends StatefulWidget {
  final String chatId;

  const ChatScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatScreen>
      createState() =>
          _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  final TextEditingController
      controller =
      TextEditingController();

  final ChatService service =
      ChatService();

  final String currentUser =
      'demoBuyerId';

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: service
                  .getMessages(
                widget.chatId,
              ),
              builder: (
                context,
                snapshot,
              ) {
                if (!snapshot
                    .hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                return ListView.builder(
                  itemCount:
                      docs.length,
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final data =
                        docs[index]
                            .data()
                            as Map<String,
                                dynamic>;

                    return MessageBubble(
                      message:
                          data[
                              'message'],
                      isMe:
                          data['senderId'] ==
                              currentUser,
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(
                    8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        controller,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'Type a message',
                    ),
                  ),
                ),

                IconButton(
                  onPressed:
                      sendMessage,
                  icon:
                      const Icon(
                    Icons.send,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void>
      sendMessage() async {
    if (controller.text
        .trim()
        .isEmpty) return;

    await service.sendMessage(
      chatId: widget.chatId,
      senderId:
          currentUser,
      receiverId:
          'demoSellerId',
      text:
          controller.text.trim(),
    );

    controller.clear();
  }
}