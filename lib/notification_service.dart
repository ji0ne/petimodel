import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showBpmAlert(String bpm) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'vital_signs_channel',
      '생체신호 알림',
      channelDescription: '심박수 관련 알림',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      '심박수 주의',
      '현재 심박수: $bpm BPM',
      platformChannelSpecifics,
    );
  }

  // 새로운 메서드 추가
  Future<void> showHealthAlert(String status, String temperature, String bpm, String state) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'health_channel',
      '건강상태 알림',
      channelDescription: '반려동물 건강상태 알림',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    String title = status == '위험' ? '건강 위험' : '건강 주의';
    String message = '현재 상태: $state\n체온: $temperature°C\n심박수: $bpm BPM';

    await _flutterLocalNotificationsPlugin.show(
      1,
      title,
      message,
      platformChannelSpecifics,
    );
  }
}