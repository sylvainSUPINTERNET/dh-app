import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'navigation/tab_navigation.dart';
import 'notifications/notification_service.dart';
import 'quotes_history/ui/quotes_history_tab.dart';
import 'theme/app_theme.dart';
import 'widgets/abstract_background.dart';
import 'widgets/dhikr_card.dart';

const _backendBaseUrl = 'http://10.0.2.2:3000';
const _deviceUuidPreferenceKey = 'device_uuid';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<String> _getOrCreateDeviceUuid() async {
  final preferences = await SharedPreferences.getInstance();
  final existingUuid = preferences.getString(_deviceUuidPreferenceKey);

  if (existingUuid != null && existingUuid.isNotEmpty) {
    return existingUuid;
  }

  final uuid = const Uuid().v4();
  await preferences.setString(_deviceUuidPreferenceKey, uuid);
  return uuid;
}

Future<void> _sendFcmTokenToBackend({
  required String fcmToken,
  required String uuid,
  required bool isRefresh,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse('$_backendBaseUrl/fcm-token'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fcmToken': fcmToken,
            'uuid': uuid,
            'isRefresh': isRefresh,
          }),
        )
        .timeout(const Duration(seconds: 5));

    debugPrint('FCM token synced (${response.statusCode})');
  } catch (error) {
    debugPrint('FCM token sync failed: $error');
  }
}

Future<void> _configureFirebaseMessaging() async {
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final deviceUuid = await _getOrCreateDeviceUuid();
    debugPrint('Device UUID: $deviceUuid');

    final token = await messaging.getToken().timeout(
      const Duration(seconds: 10),
    );
    debugPrint('FCM Token: $token');
    if (token != null) {
      unawaited(
        _sendFcmTokenToBackend(
          fcmToken: token,
          uuid: deviceUuid,
          isRefresh: false,
        ),
      );
    }

    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      unawaited(
        _sendFcmTokenToBackend(
          fcmToken: newToken,
          uuid: deviceUuid,
          isRefresh: true,
        ),
      );
    });

    await initNotifications();
  } catch (error, stackTrace) {
    debugPrint('Firebase messaging setup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // https://api.alquran.cloud/v1/ayah/1:5/editions/quran-uthmani,fr.hamidullah,ar.alafasy

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await Firebase.initializeApp();
    unawaited(_configureFirebaseMessaging());
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  Map<String, dynamic>? data;

  try {
    final response = await http
        .get(Uri.parse(_backendBaseUrl))
        .timeout(const Duration(seconds: 2));
    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
    }
  } catch (_) {}

  runApp(ProviderScope(child: MyApp(data: data)));
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
    return ValueListenableBuilder<int>(
      valueListenable: selectedTabIndex,
      builder: (context, currentTabIndex, _) {
        return Scaffold(
          body: IndexedStack(
            index: currentTabIndex,
            children: [
              _TodayTab(data: data),
              const _NotificationsTab(),
              const QuotesHistoryTab(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentTabIndex,
            onDestinationSelected: (index) {
              selectedTabIndex.value = index;
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Dhikr',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none),
                selectedIcon: Icon(Icons.notifications),
                label: 'Rappels',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history),
                label: 'Historique',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TodayTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return AbstractBackground(
      child: SafeArea(
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
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 24),
            //   child: Text(
            //     'Rappels du cœur',
            //     style: Theme.of(context).textTheme.displayLarge,
            //   ),
            // ),
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

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return AbstractBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RAPPELS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 24),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Les rappels ouverts depuis une notification arrivent ici.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
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
