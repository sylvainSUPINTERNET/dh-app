import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'notifications/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/dhikr_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //https://api.alquran.cloud/v1/ayah/1:5/editions/quran-uthmani,fr.hamidullah,ar.alafasy

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  final token = await messaging.getToken();
  debugPrint('FCM Token: $token');

  await initNotifications();

  Map<String, dynamic>? data;

  try {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000'));
    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
    }
  } catch (_) {}

  runApp(MyApp(data: data));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? data;

  const MyApp({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dhikr',
      theme: AppTheme.theme,
      home: data == null ? const ErrorPage() : HomePage(data: data!),
    );
  }
}

class HomePage extends StatelessWidget {
  final Map<String, dynamic> data;

  const HomePage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'AUJOURD\'HUI',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Rappels du cœur',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const SizedBox(height: 32),
            DhikrCard(
              quote: data['quote'] ?? 'سبحان الله',
              source: data['source'] ?? 'Dhikr',
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '✦',
              style: TextStyle(color: AppColors.accent, fontSize: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Connexion impossible',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifie ta connexion et réessaie.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
