import 'package:app_usage/app_usage.dart';
import 'package:voltwatch/core/services/logger_service.dart';

class UsageService {
  static Future<Duration> getScreenOnTime(DateTime start, DateTime end) async {
    try {
      final infoList = await AppUsage().getAppUsage(start, end);
      int totalSeconds = 0;
      for (var info in infoList) {
        totalSeconds += info.usage.inSeconds;
      }
      return Duration(seconds: totalSeconds);
    } catch (e) {
      LoggerService.instance.error('UsageService', 'Failed to get usage stats: $e');
      return Duration.zero;
    }
  }
}
