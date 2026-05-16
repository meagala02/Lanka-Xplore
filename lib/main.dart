import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'visitor_home.dart';
import 'notification_service.dart'; // FCM service

void main() async {
  // 1. Flutter engine prepare
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase connect
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. FCM Notification service initialize
  await NotificationService.initialize();

  runApp(const LankaXploreApp());
}

class LankaXploreApp extends StatelessWidget {
  const LankaXploreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.teal,
      ),
      home: const VisitorHomePage(),
    );
  }
}
