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

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked');
      },
    );
  }

  Future<void> showBpmAlert(String bpm) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'vital_signs_channel',  // 채널 ID
      '생체신호 알림',       // 채널 이름
      channelDescription: '심박수와 체온 관련 알림',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,                        // 알림 ID
      '히로의 심박수 주의',     // 알림 제목
      '현재 심박수: $bpm BPM\n정상 심박수 범위를 벗어났습니다.',  // 알림 내용
      notificationDetails,
    );
  }

  // 알림 취소
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}