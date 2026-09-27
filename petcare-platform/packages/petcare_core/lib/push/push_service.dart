import 'package:firebase_messaging/firebase_messaging.dart';
import '../api/api_client.dart';

/// Call once, right after a successful login in each app, to register this
/// device for push notifications. Re-posts the token automatically if
/// Firebase rotates it later.
///
/// Foreground notifications don't show a system tray banner by default on
/// Android — for that you'd add `flutter_local_notifications` and display
/// one manually inside the `onForegroundMessage` callback. This scaffold
/// just exposes the stream so each app can decide how to surface it
/// (a SnackBar is enough for many MVPs and is what the sample screens do).
class PushService {
  static Future<void> register(ApiClient api, {void Function(RemoteMessage)? onForegroundMessage}) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token != null) {
      await api.post('/users/fcm-token', data: {'token': token});
    }
    messaging.onTokenRefresh.listen((newToken) {
      api.post('/users/fcm-token', data: {'token': newToken});
    });

    if (onForegroundMessage != null) {
      FirebaseMessaging.onMessage.listen(onForegroundMessage);
    }
  }
}
