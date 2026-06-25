import 'package:battery_plus/battery_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/services/logger_service.dart';
import 'package:voltwatch/core/services/notification_service.dart';
import 'package:voltwatch/data/models/battery_health_record.dart';
import 'package:voltwatch/data/models/battery_log.dart';
import 'package:voltwatch/data/models/charging_session.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final log = LoggerService.instance;
    Box<BatteryLog>? box;
    try {
      log.info('BackgroundService', 'Task started: $taskName');

      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(BatteryLogAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(BatteryHealthRecordAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ChargingSessionAdapter());
      }
      box = await Hive.openBox<BatteryLog>(AppConstants.batteryLogBoxName);
      log.info('BackgroundService', 'Hive box opened');

      final battery = Battery();
      final level = await battery.batteryLevel;
      final state = await battery.batteryState;

      final stateString = _batteryStateToString(state);
      log.info('BackgroundService', 'Battery: level=$level%, state=$stateString');

      await box.add(BatteryLog(
        batteryLevel: level,
        batteryState: stateString,
        timestamp: DateTime.now(),
      ));
      log.info('BackgroundService', 'Log saved');

      final prefs = await SharedPreferences.getInstance();
      final threshold = prefs.getInt(AppConstants.thresholdKey) ?? AppConstants.defaultThreshold;
      final alertEnabled = prefs.getBool(AppConstants.alertEnabledKey) ?? true;
      final alarmEnabled = prefs.getBool(AppConstants.alarmEnabledKey) ?? false;
      final quietHoursEnabled = prefs.getBool(AppConstants.quietHoursEnabledKey) ?? false;

      log.info('BackgroundService', 'Settings: threshold=$threshold, alert=$alertEnabled, alarm=$alarmEnabled, quietHours=$quietHoursEnabled');

      final previousLevel = prefs.getInt(AppConstants.bgPreviousLevelKey);
      await prefs.setInt(AppConstants.bgPreviousLevelKey, level);

      // Only trigger on charging or full state
      final isChargingOrFull = state == BatteryState.charging || state == BatteryState.full;

      if (!isChargingOrFull) {
        // Reset charge cycle flags when not charging
        await prefs.setBool(AppConstants.bgAlertSentKey, false);
        await prefs.setBool(AppConstants.bgAlarmSentKey, false);
        log.info('BackgroundService', 'Discharging or disconnected. Reset background alert/alarm cycle flags.');
      } else if (level < threshold) {
        // Reset charge cycle flags if level dropped below threshold while charging
        await prefs.setBool(AppConstants.bgAlertSentKey, false);
        await prefs.setBool(AppConstants.bgAlarmSentKey, false);
        log.info('BackgroundService', 'Charging but level=$level < threshold=$threshold. Reset cycle flags.');
      } else if (previousLevel != null && previousLevel >= threshold) {
        log.info('BackgroundService', 'Charging but previously already above threshold ($previousLevel >= $threshold). Skipping notification.');
      } else {
        // Check quiet hours
        final isQuietHours = quietHoursEnabled && _isCurrentlyQuietHours(prefs);
        if (isQuietHours) {
          log.info('BackgroundService', 'Threshold reached but quiet hours active - notification muted');
        } else {
          final alertSent = prefs.getBool(AppConstants.bgAlertSentKey) ?? false;
          final alarmSent = prefs.getBool(AppConstants.bgAlarmSentKey) ?? false;

          if ((alertEnabled && !alertSent) || (alarmEnabled && !alarmSent)) {
            log.info('BackgroundService', 'Threshold reached: level=$level >= threshold=$threshold. Initializing notification service.');
            await NotificationService.instance.initialize();

            if (alertEnabled && !alertSent) {
              await NotificationService.instance.showThresholdAlert(level);
              await prefs.setBool(AppConstants.bgAlertSentKey, true);
              log.info('BackgroundService', 'Background alert notification sent');
            }
            if (alarmEnabled && !alarmSent) {
              await NotificationService.instance.showAlarm(level);
              await prefs.setBool(AppConstants.bgAlarmSentKey, true);
              log.info('BackgroundService', 'Background alarm notification sent');
            }
          } else {
            log.info('BackgroundService', 'Threshold reached but notifications already sent for this cycle (alertSent=$alertSent, alarmSent=$alarmSent)');
          }
        }
      }

      return true;
    } catch (e, stack) {
      log.error('BackgroundService', 'Task failed', e, stack);
      return false;
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
      }
    }
  });
}

String _batteryStateToString(BatteryState state) {
  switch (state) {
    case BatteryState.charging:
      return 'Charging';
    case BatteryState.discharging:
      return 'Discharging';
    case BatteryState.full:
      return 'Full';
    case BatteryState.connectedNotCharging:
      return 'Discharging';
    case BatteryState.unknown:
      return 'Discharging';
  }
}

bool _isCurrentlyQuietHours(SharedPreferences prefs) {
  final now = DateTime.now();
  final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  final startTime = prefs.getString(AppConstants.quietHoursStartKey) ?? '22:00';
  final endTime = prefs.getString(AppConstants.quietHoursEndKey) ?? '08:00';
  return AppConstants.isTimeInQuietHours(currentTime, startTime, endTime);
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    LoggerService.instance.info('BackgroundService', 'Workmanager initialized');
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      AppConstants.backgroundTaskName,
      AppConstants.backgroundTaskName,
      frequency: AppConstants.logInterval,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    LoggerService.instance.info('BackgroundService', 'Periodic task registered');
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    LoggerService.instance.info('BackgroundService', 'All tasks cancelled');
  }
}
