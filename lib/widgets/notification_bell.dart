import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notifications/notification_service.dart';

class NotificationBell extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;

  const NotificationBell({
    super.key,
    required this.onPressed,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return IconButton(
        tooltip: 'Notifications',
        onPressed: onPressed,
        icon: Icon(Icons.notifications_none, color: color),
      );
    }

    return StreamBuilder<int>(
      stream: NotificationService.instance.unreadCount(user.uid),
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: onPressed,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none, color: color),
              if (count > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
