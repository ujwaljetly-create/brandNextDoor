import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final bool isRead;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0C2430);
    const gold = Color(0xFFC99245);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
        decoration: BoxDecoration(
          color: isMe ? navy : const Color(0xFFF0E7DA),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                style: TextStyle(
                  color: isMe ? Colors.white : navy,
                  height: 1.35,
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 15,
                    color: isRead ? gold : Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isRead ? 'Read' : 'Sent',
                    style: TextStyle(
                      color: isRead ? gold : Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
