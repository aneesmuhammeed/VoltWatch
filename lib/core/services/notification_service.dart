import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/services/alarm_player_service.dart';
import 'package:voltwatch/core/services/logger_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings(AppConstants.notificationIcon);
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          if (response.actionId == 'stop_alarm') {
            LoggerService.instance.info('NotificationService', 'Stop Alarm action clicked from notification');
            await AlarmPlayerService.instance.stopAlarm();
          }
        },
      );
      _initialized = true;
      LoggerService.instance.info('NotificationService', 'Notification service initialized successfully');
    } catch (e, stackTrace) {
      LoggerService.instance.error('NotificationService', 'Failed to initialize notification service', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      final granted = status.isGranted;
      LoggerService.instance.info('NotificationService', 'Notification permission request completed. Status: $status, Granted: $granted');
      return granted;
    } catch (e, stackTrace) {
      LoggerService.instance.error('NotificationService', 'Error requesting notification permission', e, stackTrace);
      return false;
    }
  }

  static const int _thresholdAlertId = 1000;
  static const int _alarmBaseId = 2000;
  static const int _saverBaseId = 3000;
  static const int _tempBaseId = 4000;
  static const int _summaryId = 5000;

  Future<void> showThresholdAlert(int batteryLevel) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: AppConstants.notificationIcon,
        styleInformation: BigTextStyleInformation(
          'Your device battery has reached $batteryLevel%.\n'
              'Tap to open VoltWatch and check battery status.',
          contentTitle: 'Battery Alert',
          summaryText: 'Battery at $batteryLevel%',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        _thresholdAlertId,
        'Battery Alert',
        'Your device battery has reached $batteryLevel%',
        details,
      );
      LoggerService.instance.info('NotificationService', 'Threshold alert shown successfully for level: $batteryLevel%');
    } catch (e, stackTrace) {
      LoggerService.instance.error('NotificationService', 'Failed to show threshold alert for level: $batteryLevel%', e, stackTrace);
    }
  }

  Future<void> showAlarm(int batteryLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundUrl = prefs.getString(AppConstants.alarmSoundKey) ??
          AppConstants.defaultAlarmSoundUrl;

      await AlarmPlayerService.instance.playAlarm(soundUrl: soundUrl);

      final androidDetails = AndroidNotificationDetails(
        AppConstants.alarmChannelId,
        AppConstants.alarmChannelName,
        channelDescription: AppConstants.alarmChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: AppConstants.notificationIcon,
        playSound: true,
        sound: const UriAndroidNotificationSound('content://settings/system/alarm_alert'),
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT for looping
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'stop_alarm',
            'Stop Alarm',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
        styleInformation: BigTextStyleInformation(
          'ALARM: Your device battery has reached $batteryLevel%.\n'
              'Please check your device.',
          contentTitle: 'Battery Alarm',
          summaryText: 'Battery at $batteryLevel%',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
      _alarmBaseId,
        'Battery Alarm',
        'ALARM: Battery reached $batteryLevel%',
        details,
      );
      LoggerService.instance.info('NotificationService', 'Alarm notification shown successfully for level: $batteryLevel%');
    } catch (e, stackTrace) {
      LoggerService.instance.error('NotificationService', 'Failed to show alarm notification for level: $batteryLevel%', e, stackTrace);
    }
  }

  Future<void> showBatterySaverSuggestion(int batteryLevel) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: 'Suggests unplugging at 80% for battery health',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: AppConstants.notificationIcon,
        styleInformation: BigTextStyleInformation(
          'Battery at $batteryLevel% — consider unplugging to preserve long-term battery health.\n'
              'Charging past 80% repeatedly can accelerate battery degradation.',
          contentTitle: 'Battery Saver',
          summaryText: 'Unplug to preserve battery health',
        ),
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      await _plugin.show(
      _saverBaseId,
      'Battery Saver',
        'Battery at $batteryLevel% — consider unplugging',
        details,
      );
    } catch (e) {
      LoggerService.instance.error('NotificationService', 'Failed to show battery saver notification', e);
    }
  }

  Future<void> showTemperatureAlert(double temperature) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: 'Alerts for high battery temperature',
        importance: Importance.high,
        priority: Priority.high,
        icon: AppConstants.notificationIcon,
        styleInformation: BigTextStyleInformation(
          'Battery temperature is ${temperature.toStringAsFixed(1)}°C — unplug and let the device cool down.',
          contentTitle: 'High Battery Temperature',
          summaryText: 'Device may be overheating',
        ),
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      await _plugin.show(
      _tempBaseId,
      'High Battery Temperature',
        'Battery at ${temperature.toStringAsFixed(1)}°C — unplug to cool down',
        details,
      );
    } catch (e) {
      LoggerService.instance.error('NotificationService', 'Failed to show temperature alert', e);
    }
  }

  Future<void> showDailySummary(int avgLevel, int high, int low, int cycles, double? avgTemp) async {
    try {
      final tempStr = avgTemp != null ? '\nAvg Temp: ${avgTemp.toStringAsFixed(1)}°C' : '';
      final androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: AppConstants.notificationIcon,
        styleInformation: BigTextStyleInformation(
          'Today\'s battery summary:\n'
              'Average: $avgLevel% | High: $high% | Low: $low%\n'
              'Charge cycles: $cycles$tempStr',
          contentTitle: 'Daily Battery Summary',
          summaryText: 'Avg: $avgLevel%',
        ),
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      await _plugin.show(
      _summaryId,
      'Daily Battery Summary',
        'Avg: $avgLevel% | High: $high% | Low: $low% | Cycles: $cycles',
        details,
      );
    } catch (e) {
      LoggerService.instance.error('NotificationService', 'Failed to show daily summary', e);
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      LoggerService.instance.info('NotificationService', 'All notifications cancelled successfully');
    } catch (e, stackTrace) {
      LoggerService.instance.error('NotificationService', 'Failed to cancel all notifications', e, stackTrace);
    }
  }
}
