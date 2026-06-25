import 'package:voltwatch/data/models/battery_insights.dart';
import 'package:voltwatch/data/models/battery_log.dart';
import 'package:voltwatch/data/models/charging_session.dart';

class AnalyticsState {
  final List<BatteryLog> logs;
  final List<ChargingSession> chargingSessions;
  final double? screenOnDrainPerHour;
  final double? bgDrainPerHour;
  final BatteryInsights? insights;
  final bool isLoading;
  final int displayedLogCount;

  static const int defaultLogPageSize = 50;

  const AnalyticsState({
    this.logs = const [],
    this.chargingSessions = const [],
    this.screenOnDrainPerHour,
    this.bgDrainPerHour,
    this.insights,
    this.isLoading = true,
    this.displayedLogCount = defaultLogPageSize,
  });

  AnalyticsState copyWith({
    List<BatteryLog>? logs,
    List<ChargingSession>? chargingSessions,
    double? screenOnDrainPerHour,
    double? bgDrainPerHour,
    BatteryInsights? insights,
    bool? isLoading,
    int? displayedLogCount,
  }) {
    return AnalyticsState(
      logs: logs ?? this.logs,
      chargingSessions: chargingSessions ?? this.chargingSessions,
      screenOnDrainPerHour: screenOnDrainPerHour ?? this.screenOnDrainPerHour,
      bgDrainPerHour: bgDrainPerHour ?? this.bgDrainPerHour,
      insights: insights ?? this.insights,
      isLoading: isLoading ?? this.isLoading,
      displayedLogCount: displayedLogCount ?? this.displayedLogCount,
    );
  }
}
