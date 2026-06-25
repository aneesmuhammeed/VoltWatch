import 'package:voltwatch/core/services/logger_service.dart';
import 'package:voltwatch/core/services/notification_service.dart';
import 'package:voltwatch/data/repositories/battery_log_repository.dart';
import 'package:voltwatch/data/repositories/settings_repository.dart';

class BatterySummaryService {
  static final BatterySummaryService _instance = BatterySummaryService._();
  static BatterySummaryService get instance => _instance;
  BatterySummaryService._();

  DateTime? _lastSummaryDate;

  Future<void> checkAndSendSummary(
    BatteryLogRepository logRepo,
    SettingsRepository settingsRepo,
  ) async {
    if (!settingsRepo.isSummaryNotificationEnabled()) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Only send once per day
    if (_lastSummaryDate != null && _lastSummaryDate == today) return;

    final targetHour = settingsRepo.getSummaryNotificationHour();
    if (now.hour != targetHour || now.minute > 5) return;

    _lastSummaryDate = today;

    try {
      final insights = await logRepo.getTodayInsights();
      if (insights == null) return;

      final cycleCount = settingsRepo.getChargeCycleCount();

      await NotificationService.instance.showDailySummary(
        insights.average,
        insights.highest,
        insights.lowest,
        cycleCount,
        insights.avgTemperature,
      );
      LoggerService.instance.info('BatterySummary', 'Daily summary sent');
    } catch (e) {
      LoggerService.instance.error('BatterySummary', 'Failed to send summary', e);
    }
  }
}
