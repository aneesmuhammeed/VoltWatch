import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voltwatch/core/providers/providers.dart';
import 'package:voltwatch/data/repositories/battery_log_repository.dart';
import 'package:voltwatch/data/datasources/charging_session_local.dart';
import 'package:voltwatch/core/services/usage_service.dart';
import 'analytics_state.dart';

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  late final BatteryLogRepository _logRepo;
  late final ChargingSessionLocalDatasource _chargingSessionDb;

  @override
  AnalyticsState build() {
    _logRepo = ref.watch(batteryLogRepositoryProvider);
    _chargingSessionDb = ref.watch(chargingSessionLocalDatasourceProvider);
    
    // Load data initially
    Future.microtask(() => loadData());

    return const AnalyticsState(isLoading: true);
  }

  Future<void> loadData() async {
    final logs = await _logRepo.getAllLogs();
    final insights = await _logRepo.getTodayInsights();
    final sessions = await _chargingSessionDb.getAllSessions();
    
    // Calculate drain
    double? screenOnDrain;
    double? bgDrain;
    if (insights != null && logs.isNotEmpty) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final screenOnDuration = await UsageService.getScreenOnTime(startOfDay, now);
      
      final totalDrainHours = now.difference(startOfDay).inMinutes / 60.0;
      if (totalDrainHours > 0) {
        final screenOnHours = screenOnDuration.inMinutes / 60.0;
        final bgHours = totalDrainHours - screenOnHours;
        
        final totalDrain = insights.drainRatePerHour * totalDrainHours;
        if (screenOnHours > 0 && bgHours > 0) {
          final x = totalDrain / (3 * screenOnHours + bgHours);
          bgDrain = x;
          screenOnDrain = 3 * x;
        } else if (screenOnHours > 0) {
          screenOnDrain = totalDrain / screenOnHours;
          bgDrain = 0;
        } else if (bgHours > 0) {
          bgDrain = totalDrain / bgHours;
          screenOnDrain = 0;
        }
      }
    }

    state = state.copyWith(
      logs: logs,
      insights: insights,
      chargingSessions: sessions,
      screenOnDrainPerHour: screenOnDrain,
      bgDrainPerHour: bgDrain,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    await loadData();
  }

  void loadMoreLogs() {
    if (state.displayedLogCount < state.logs.length) {
      state = state.copyWith(
        displayedLogCount: state.displayedLogCount + AnalyticsState.defaultLogPageSize,
      );
    }
  }

  Future<void> clearAll() async {
    await _logRepo.clearAll();
    state = const AnalyticsState(isLoading: false);
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsState>(() {
  return AnalyticsNotifier();
});
