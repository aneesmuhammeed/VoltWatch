import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Battery color thresholds
  static const int batteryHighThreshold = 80;
  static const int batteryMediumThreshold = 40;

  static const Color batteryHighColor = Color(0xFF10B981);
  static const Color batteryMediumColor = Color(0xFFF59E0B);
  static const Color batteryLowColor = Color(0xFFEF4444);

  static Color batteryColor(int level) {
    if (level >= batteryHighThreshold) return batteryHighColor;
    if (level >= batteryMediumThreshold) return batteryMediumColor;
    return batteryLowColor;
  }

  // Background task configuration
  static const String backgroundTaskName = 'com.gurucool.voltwatch.batteryLog';
  static const Duration logInterval = Duration(minutes: 15);
  static const Duration batteryPollInterval = Duration(seconds: 30);

  // Notification channels
  static const String notificationChannelId = 'voltwatch_alerts';
  static const String notificationChannelName = 'Battery Alerts';
  static const String notificationChannelDesc =
      'Notifications for battery threshold alerts';

  static const String alarmChannelId = 'voltwatch_alarms';
  static const String alarmChannelName = 'Battery Alarms';
  static const String alarmChannelDesc =
      'Audible alarms for battery threshold alerts';

  // Hive box names
  static const String batteryLogBoxName = 'battery_logs';

  // SharedPreferences keys
  static const String thresholdKey = 'alert_threshold';
  static const String themeModeKey = 'theme_mode';
  static const String alertEnabledKey = 'alert_enabled';
  static const String alarmEnabledKey = 'alarm_enabled';
  static const String alarmSoundEnabledKey = 'alarm_sound_enabled';
  static const String cachedChargeRateKey = 'cached_charge_rate';
  static const String alarmSoundKey = 'alarm_sound_url';
  static const String quietHoursEnabledKey = 'quiet_hours_enabled';
  static const String quietHoursStartKey = 'quiet_hours_start'; // HH:mm format
  static const String quietHoursEndKey = 'quiet_hours_end'; // HH:mm format
  static const String defaultAlarmSoundUrl = 'https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg';

  // Quick preset thresholds
  static const List<int> quickPresets = [20, 50, 80];
  static const Map<int, String> presetLabels = {
    20: 'Critical',
    50: 'Balanced',
    80: 'Optimal',
  };

  static const List<Map<String, String>> alarmSounds = [
    {
      'name': 'Classic Digital',
      'url': 'https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg',
    },
    {
      'name': 'Breeze Bells',
      'url': 'https://actions.google.com/sounds/v1/alarms/mechanical_clock_ring.ogg',
    },
    {
      'name': 'Military Bugle',
      'url': 'https://actions.google.com/sounds/v1/alarms/bugle_tune.ogg',
    },
    {
      'name': 'Classic Alarm',
      'url': 'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg',
    },
  ];

  // Battery Saver Mode
  static const String batterySaverEnabledKey = 'battery_saver_enabled';
  static const int batterySaverThreshold = 80;

  // Battery Health
  static const String batteryHealthBoxName = 'battery_health';
  static const String chargingSessionBoxName = 'charging_sessions';
  static const String chargeCycleCountKey = 'charge_cycle_count';
  static const String partialChargeKey = 'partial_charge_accumulator';

  // Daily summary notification
  static const String summaryNotificationEnabledKey = 'summary_notification_enabled';
  static const String summaryNotificationHourKey = 'summary_notification_hour';
  static const int defaultSummaryHour = 20; // 8 PM

  // Background task SharedPreferences keys
  static const String bgPreviousLevelKey = 'bg_previous_level';
  static const String bgAlertSentKey = 'bg_alert_sent';
  static const String bgAlarmSentKey = 'bg_alarm_sent';

  // Charging session tracking keys
  static const String chargingSessionStartTimeKey = 'charging_session_start_time';
  static const String chargingSessionStartLevelKey = 'charging_session_start_level';

  // Default values
  static const int defaultThreshold = 80;

  /// Checks if the given [currentTime] (HH:mm) falls within quiet hours
  /// defined by [startTime] and [endTime] (HH:mm).
  static bool isTimeInQuietHours(String currentTime, String startTime, String endTime) {
    if (startTime.compareTo(endTime) > 0) {
      // Quiet hours span midnight (e.g., 22:00 to 08:00)
      return currentTime.compareTo(startTime) >= 0 || currentTime.compareTo(endTime) < 0;
    } else {
      // Quiet hours don't span midnight
      return currentTime.compareTo(startTime) >= 0 && currentTime.compareTo(endTime) < 0;
    }
  }

  // App info
  static const String appName = 'VoltWatch';
  static const String appVersion = '1.0.0';

  // Notification icon
  static const String notificationIcon = '@drawable/ic_notification';
}
