import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;
  ApiClient? _apiClient;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  /// Initialize Firebase & Local Notifications defensively.
  /// If Firebase configuration (e.g., google-services.json) is missing,
  /// this method logs an informative message and returns cleanly without throwing.
  Future<void> initialize({
    ApiClient? apiClient,
    void Function(RemoteMessage message)? onNotificationTap,
  }) async {
    _apiClient = apiClient ?? ApiClient();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      developer.log(
        'PushNotificationService: Firebase not initialized (configuration missing): $e',
        name: 'ServioPush',
      );
      return;
    }

    try {
      // 1. Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Setup local notifications for Android foreground banners
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Local notification clicked in foreground
        },
      );

      // Create Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        'servio_high_importance',
        'Servio Notifications',
        description:
            'High importance notifications for appointments, repairs, and updates.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 3. Request permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        developer.log('PushNotificationService: User denied notifications permission',
            name: 'ServioPush');
        return;
      }

      // 4. Retrieve initial token
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null) {
        developer.log('PushNotificationService: FCM token acquired',
            name: 'ServioPush');
        _syncTokenToBackend();
      }

      // 5. Listen to token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _syncTokenToBackend();
      });

      // 6. Foreground notifications display
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                androidChannel.id,
                androidChannel.name,
                channelDescription: androidChannel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: message.data['actionUrl'] ?? '',
          );
        }
      });

      // 7. Handle app opening from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (onNotificationTap != null) {
          onNotificationTap(message);
        }
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && onNotificationTap != null) {
        onNotificationTap(initialMessage);
      }

      _initialized = true;
    } catch (e) {
      developer.log('PushNotificationService initialization error: $e',
          name: 'ServioPush');
    }
  }

  /// Update the ApiClient instance after user authentication to ensure token is synced.
  void updateApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
    if (_fcmToken != null) {
      _syncTokenToBackend();
    }
  }

  /// Trigger synchronization of current FCM token to backend
  Future<void> syncToken({ApiClient? client}) async {
    if (client != null) {
      _apiClient = client;
    } else {
      _apiClient ??= ApiClient();
    }
    await _syncTokenToBackend();
  }

  Future<void> _syncTokenToBackend() async {
    if (_fcmToken == null || _apiClient == null) return;

    try {
      final deviceType = defaultTargetPlatform == TargetPlatform.iOS
          ? 'IOS'
          : defaultTargetPlatform == TargetPlatform.android
              ? 'ANDROID'
              : 'WEB';

      await _apiClient!.post(
        '/notifications/devices',
        body: {
          'token': _fcmToken,
          'deviceType': deviceType,
        },
      );
      developer.log('PushNotificationService: Device token registered with backend',
          name: 'ServioPush');
    } catch (e) {
      // 401 or network offline is ignored safely until next sync
      developer.log('PushNotificationService: Token sync deferred: $e',
          name: 'ServioPush');
    }
  }
}
