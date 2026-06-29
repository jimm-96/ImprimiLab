import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Settings state
  bool isScheduledActive = false;
  String scheduledTitle = 'Recordatorio de Proyecto';
  String scheduledBody = '¡Tu proyecto de impresión 3D estimado ya ha finalizado!';
  DateTime? scheduledTime;

  bool isRecurringActive = false;
  String recurringTitle = 'Control de Stock e Impresoras';
  String recurringBody = 'Recuerda revisar el nivel de filamento/resina y el estado de tus impresoras.';
  TimeOfDay recurringTime = const TimeOfDay(hour: 9, minute: 0);

  // Notification IDs
  static const int testNotificationId = 999;
  static const int testScheduledNotificationId = 998;
  static const int uniqueScheduledNotificationId = 1001;
  static const int recurringNotificationId = 1002;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification tapped: ${response.payload}");
      },
    );

    await loadSettings();
    _isInitialized = true;
  }

  Future<bool> checkPermission() async {
    final bool? isGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return isGranted ?? false;
  }

  Future<bool> requestPermissions() async {
    bool androidGranted = false;
    bool iosGranted = false;

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      androidGranted = await androidImplementation.requestNotificationsPermission() ?? false;
    }

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      iosGranted = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return androidGranted || iosGranted;
  }

  // Load configuration from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isScheduledActive = prefs.getBool('notif_scheduled_active') ?? false;
    scheduledTitle = prefs.getString('notif_scheduled_title') ?? 'Recordatorio de Proyecto';
    scheduledBody = prefs.getString('notif_scheduled_body') ?? '¡Tu proyecto de impresión 3D estimado ya ha finalizado!';
    
    final scheduledTimeStr = prefs.getString('notif_scheduled_time');
    if (scheduledTimeStr != null) {
      scheduledTime = DateTime.tryParse(scheduledTimeStr);
    }

    isRecurringActive = prefs.getBool('notif_recurring_active') ?? false;
    recurringTitle = prefs.getString('notif_recurring_title') ?? 'Control de Stock e Impresoras';
    recurringBody = prefs.getString('notif_recurring_body') ?? 'Recuerda revisar el nivel de filamento/resina y el estado de tus impresoras.';
    
    final recHour = prefs.getInt('notif_recurring_hour') ?? 9;
    final recMin = prefs.getInt('notif_recurring_minute') ?? 0;
    recurringTime = TimeOfDay(hour: recHour, minute: recMin);
  }

  // Save configuration to SharedPreferences
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_scheduled_active', isScheduledActive);
    await prefs.setString('notif_scheduled_title', scheduledTitle);
    await prefs.setString('notif_scheduled_body', scheduledBody);
    if (scheduledTime != null) {
      await prefs.setString('notif_scheduled_time', scheduledTime!.toIso8601String());
    } else {
      await prefs.remove('notif_scheduled_time');
    }

    await prefs.setBool('notif_recurring_active', isRecurringActive);
    await prefs.setString('notif_recurring_title', recurringTitle);
    await prefs.setString('notif_recurring_body', recurringBody);
    await prefs.setInt('notif_recurring_hour', recurringTime.hour);
    await prefs.setInt('notif_recurring_minute', recurringTime.minute);
  }

  // 1. Immediate Test Notification
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'imprimilab_test_channel',
      'Canal de Pruebas',
      channelDescription: 'Canal usado para notificaciones de prueba de ImprimiLab',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // 2. Scheduled Notification (Unique)
  Future<void> scheduleUniqueNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'imprimilab_scheduled_channel',
      'Recordatorios Únicos',
      channelDescription: 'Recordatorios de entrega y finalización de proyectos',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 3. Recurring Notification (Daily at specific time)
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'imprimilab_recurring_channel',
      'Recordatorios Recurrentes',
      channelDescription: 'Alertas periódicas de control de inventario y estado',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = _nextInstanceOfTime(time);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Update and reschedule all active notifications based on current settings
  Future<void> updateScheduledNotifications() async {
    await saveSettings();

    // Cancel existing scheduled & recurring notifications
    await _notificationsPlugin.cancel(id: uniqueScheduledNotificationId);
    await _notificationsPlugin.cancel(id: recurringNotificationId);

    if (isScheduledActive && scheduledTime != null) {
      await scheduleUniqueNotification(
        id: uniqueScheduledNotificationId,
        title: scheduledTitle,
        body: scheduledBody,
        scheduledDate: scheduledTime!,
      );
    }

    if (isRecurringActive) {
      await scheduleRecurringNotification(
        id: recurringNotificationId,
        title: recurringTitle,
        body: recurringBody,
        time: recurringTime,
      );
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    isScheduledActive = false;
    isRecurringActive = false;
    await saveSettings();
  }

  // Check currently pending requests
  Future<List<PendingNotificationRequest>> getPendingRequests() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
