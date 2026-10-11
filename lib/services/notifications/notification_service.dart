import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationSubscription;
  String? _registeredUid;
  String? _token;
  bool _notificationStreamReady = false;

  Future<void> initialize() async {
    if (_authSubscription != null) return;

    // FCM handles system notifications while the app is backgrounded/closed.
    // Foreground banners are driven by the Firestore notification record below,
    // which also keeps the bell badge and Notifications page in sync.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((_) {});
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(_handleAuthChanged);
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) async {
      _token = token;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) await _saveToken(user.uid, token);
    });
  }

  Future<void> _handleAuthChanged(User? user) async {
    final previousUid = _registeredUid;
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _notificationStreamReady = false;

    if (user == null) {
      if (previousUid != null && _token != null) await _removeToken(previousUid, _token!);
      _registeredUid = null;
      return;
    }

    _listenForForegroundNotifications(user.uid);

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false);
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      if (previousUid != null && previousUid != user.uid) await _removeToken(previousUid, token);
      _token = token;
      _registeredUid = user.uid;
      await _saveToken(user.uid, token);
    } catch (e) {
      debugPrint('Unable to register notification token: $e');
    }
  }

  void _listenForForegroundNotifications(String uid) {
    _notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      if (!_notificationStreamReady) {
        _notificationStreamReady = true;
        return;
      }
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;
        final title = (data['title'] ?? 'New notification').toString().trim();
        final body = (data['body'] ?? '').toString().trim();
        final text = body.isEmpty ? title : '$title\n$body';
        scaffoldMessengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 5)));
      }
    });
  }

  Stream<int> unreadCount(String uid) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.where((doc) => doc.data()['read'] != true).length);
  }

  Future<void> _saveToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'notificationsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _removeToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
        'notificationsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) { debugPrint('Unable to remove notification token: $e'); }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _notificationSubscription?.cancel();
    _authSubscription = null;
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _notificationSubscription = null;
  }
}
