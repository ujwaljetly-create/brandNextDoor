import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String peerId;
  final String peerName;
  final String peerLogoUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.peerId,
    required this.peerName,
    this.peerLogoUrl = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ChatService service = ChatService();

  String get currentUser => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  Future<void> _markRead() async {
    if (currentUser.isEmpty) return;
    await service.markMessagesRead(chatId: widget.chatId, userId: currentUser);
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || currentUser.isEmpty) return;

    controller.clear();
    await service.sendMessage(
      chatId: widget.chatId,
      senderId: currentUser,
      receiverId: widget.peerId,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFE8D4B8),
              backgroundImage: widget.peerLogoUrl.isNotEmpty
                  ? NetworkImage(widget.peerLogoUrl)
                  : null,
              child: widget.peerLogoUrl.isEmpty
                  ? const Icon(Icons.storefront_outlined, color: _navy, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Messages',
                    style: TextStyle(color: Color(0xFF748087), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: service.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markRead();
                  if (scrollController.hasClients) {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  }
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Start the conversation with this local seller.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return MessageBubble(
                      message: (data['message'] ?? '').toString(),
                      isMe: data['senderId'] == currentUser,
                      isRead: data['isRead'] == true,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: const Color(0xFFF5F1EB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
