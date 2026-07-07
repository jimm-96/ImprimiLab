import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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

  bool isLowMaterialActive = false;
  double lowMaterialThreshold = 100.0;

  // Notification IDs
  static const int testNotificationId = 999;
  static const int testScheduledNotificationId = 998;
  static const int uniqueScheduledNotificationId = 1001;
  static const int recurringNotificationId = 1002;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        String timeZoneName = timeZoneInfo.identifier;
        if (timeZoneName == 'GMT') {
          timeZoneName = 'UTC';
        }
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint("[Notificaciones] Zona horaria configurada con éxito: $timeZoneName");
      } catch (e) {
        debugPrint("Could not set local timezone, falling back: $e");
        try {
          tz.setLocalLocation(tz.getLocation('America/Santiago'));
        } catch (_) {
          tz.setLocalLocation(tz.UTC);
        }
      }

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
    } catch (e) {
      debugPrint("Error al inicializar notificaciones locales: $e");
    }
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

    isLowMaterialActive = prefs.getBool('notif_low_material_active') ?? false;
    lowMaterialThreshold = prefs.getDouble('notif_low_material_threshold') ?? 100.0;
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

    await prefs.setBool('notif_low_material_active', isLowMaterialActive);
    await prefs.setDouble('notif_low_material_threshold', lowMaterialThreshold);
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
    bool isTest = false,
  }) async {
    try {
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

      final tzNow = tz.TZDateTime.now(tz.local);
      
      // If it is a test alarm, schedule exactly 5 seconds in the future relative to the timezone's current clock.
      // Otherwise, construct it using the wall-clock fields selected by the user.
      final tzDate = isTest
          ? tzNow.add(const Duration(seconds: 5))
          : tz.TZDateTime(
              tz.local,
              scheduledDate.year,
              scheduledDate.month,
              scheduledDate.day,
              scheduledDate.hour,
              scheduledDate.minute,
              scheduledDate.second,
            );

      debugPrint("[Notificaciones] Zona Horaria Activa: ${tz.local.name}");
      debugPrint("[Notificaciones] Hora local en zona: $tzNow");
      debugPrint("[Notificaciones] Programando alarma para: $tzDate (isTest: $isTest)");

      if (tzDate.isBefore(tzNow)) {
        debugPrint("[Notificaciones] ERROR: La fecha programada $tzDate ya pasó respecto al tiempo local $tzNow. Cancelando registro.");
        return;
      }

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint("[Notificaciones] Éxito: Alerta única programada con ID: $id para $tzDate");
    } catch (e, stack) {
      debugPrint("[Notificaciones] Fallo al programar alerta única (ID: $id): $e\n$stack");
    }
  }

  // 3. Recurring Notification (Daily at specific time)
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    try {
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
      final tzNow = tz.TZDateTime.now(tz.local);
      debugPrint("[Notificaciones] Programando recurrencia diaria");
      debugPrint("[Notificaciones] Siguiente ejecución estimada: $scheduledDate (Zona: ${tz.local.name}, Hora Actual: $tzNow)");

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint("[Notificaciones] Éxito: Alerta recurrente programada con ID: $id");
    } catch (e, stack) {
      debugPrint("[Notificaciones] Fallo al programar alerta recurrente (ID: $id): $e\n$stack");
    }
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
    try {
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
      debugPrint("Successfully updated scheduled notifications configuration.");
    } catch (e) {
      debugPrint("Error updating scheduled notifications configuration: $e");
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
      isScheduledActive = false;
      isRecurringActive = false;
      await saveSettings();
      debugPrint("Successfully cancelled all system notifications.");
    } catch (e) {
      debugPrint("Error cancelling all notifications: $e");
    }
  }

  // Check currently pending requests
  Future<List<PendingNotificationRequest>> getPendingRequests() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
