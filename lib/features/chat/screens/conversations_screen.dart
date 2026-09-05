import 'package:flutter/material.dart';

import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.store),
            ),
            title: const Text(
              "GlowCraft",
            ),
            subtitle: const Text(
              "Last message",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ChatScreen(
                    chatId:
                        'sampleChatId',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}