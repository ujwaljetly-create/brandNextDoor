import 'package:flutter/material.dart';

class MessageBubble
    extends StatelessWidget {
  final String message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(
      BuildContext context) {
    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.all(8),
        padding:
            const EdgeInsets.all(
          12,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.deepPurple
              : Colors.grey.shade300,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isMe
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }
}