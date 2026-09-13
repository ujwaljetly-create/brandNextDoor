import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'services/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: '.env',
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: BrandNextDoor(),
    ),
  );
}

class BrandNextDoor extends StatelessWidget {
  const BrandNextDoor({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Brand Next Door',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: NotificationService.instance.scaffoldMessengerKey,
      routerConfig: AppRouter.router,
    );
  }
}
