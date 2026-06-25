import 'dart:async';
import 'package:battery_plus/battery_plus.dart' as bp;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/providers/providers.dart';
import 'package:voltwatch/core/services/battery_summary_service.dart';
import 'package:voltwatch/core/services/battery_temperature_service.dart';
import 'package:voltwatch/core/services/home_widget_service.dart';
import 'package:voltwatch/core/services/logger_service.dart';
import 'package:voltwatch/core/services/notification_service.dart';
import 'package:voltwatch/data/datasources/charging_session_local.dart';
import 'package:voltwatch/data/models/battery_health_record.dart';
import 'package:voltwatch/data/models/battery_log.dart';
import 'package:voltwatch/data/models/charging_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltwatch/data/repositories/battery_repository.dart';
import 'package:voltwatch/data/repositories/battery_log_repository.dart';
import 'package:voltwatch/data/repositories/settings_repository.dart';
import 'battery_state.dart';

class BatteryNotifier extends Notifier<BatteryState> {
  late final BatteryRepository _batteryRepo;
  late final BatteryLogRepository _logRepo;
  late final SettingsRepository _settingsRepo;
  late final ChargingSessionLocalDatasource _chargingSessionDb;

  StreamSubscription<bp.BatteryState>? _stateSubscription;
  Timer? _pollTimer;

  final List<_LevelSample> _chargeSamples = [];
  bool _alertSentForCurrentCharge = false;
  bool _alarmSentForCurrentCharge = false;
  bool _saverNotifiedForCurrentCharge = false;
  int? _previousLevel;
  DateTime? _lastLogTime;
  String? _previousBatteryState;
  int? _previousHealthMax;

  @override
  BatteryState build() {
    _batteryRepo = ref.watch(batteryRepositoryProvider);
    _logRepo = ref.watch(batteryLogRepositoryProvider);
    _settingsRepo = ref.watch(settingsRepositoryProvider);
    _chargingSessionDb = ref.watch(chargingSessionLocalDatasourceProvider);

    ref.onDispose(() {
      _stateSubscription?.cancel();
      _pollTimer?.cancel();
      LoggerService.instance.info('BatteryNotifier', 'Disposed');
    });

    // Clear any stale charging session tracking data on fresh start
    unawaited(_clearStaleSessionData());

    return const BatteryState(isLoading: true);
  }

  Future<void> _clearStaleSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeStr = prefs.getString(AppConstants.chargingSessionStartTimeKey);
      if (startTimeStr != null) {
        final startTime = DateTime.tryParse(startTimeStr);
        if (startTime != null) {
          final age = DateTime.now().difference(startTime);
          if (age.inHours > 24) {
            await prefs.remove(AppConstants.chargingSessionStartTimeKey);
            await prefs.remove(AppConstants.chargingSessionStartLevelKey);
            LoggerService.instance.info('BatteryNotifier', 'Cleared stale charging session data');
          }
        }
      }
    } catch (_) {
      // Best effort cleanup
    }
  }

  Future<void> startMonitoring() async {
    try {
      final level = await _batteryRepo.getBatteryLevel();
      final batteryState = await _batteryRepo.getBatteryState();
      final stateString = BatteryRepository.stateToString(batteryState);

      LoggerService.instance.info('BatteryNotifier', 'Started: level=$level%, state=$stateString');

      if (batteryState != bp.BatteryState.charging && batteryState != bp.BatteryState.full) {
        _alertSentForCurrentCharge = false;
        _alarmSentForCurrentCharge = false;
        _saverNotifiedForCurrentCharge = false;
      }

      final isCharging = batteryState == bp.BatteryState.charging;
      final estimate = _getEstimate(isCharging, level);

      state = state.copyWith(
        level: level,
        state: stateString,
        isLoading: false,
        estimatedMinutesToFull: estimate,
        batterySaverEnabled: _settingsRepo.isBatterySaverEnabled(),
        chargeCycleCount: _settingsRepo.getChargeCycleCount(),
      );

      unawaited(HomeWidgetService.instance.updateWidget(state, _settingsRepo));

      // Load health degradation
      _loadHealth();

      _stateSubscription = _batteryRepo.onBatteryStateChanged.listen((newState) {
        final stateStr = BatteryRepository.stateToString(newState);
        LoggerService.instance.info('BatteryNotifier', 'State changed: $stateStr');

        _handleSessionTracking(stateStr, state.level);

        if (stateStr != 'Charging') {
          _chargeSamples.clear();
        }
        if (stateStr != 'Charging' && stateStr != 'Full') {
          _alertSentForCurrentCharge = false;
          _alarmSentForCurrentCharge = false;
          _saverNotifiedForCurrentCharge = false;
        }
        final isCharging = stateStr == 'Charging';
        final estimate = _getEstimate(isCharging, state.level);

        state = state.copyWith(
          state: stateStr,
          estimatedMinutesToFull: estimate,
        );
        unawaited(HomeWidgetService.instance.updateWidget(state, _settingsRepo));
        _trackChargeCycle(state.level, stateStr);

        if (newState == bp.BatteryState.charging && _previousBatteryState != 'Charging') {
          HapticFeedback.heavyImpact();
        }
        _previousBatteryState = stateStr;
      });

      _pollTimer = Timer.periodic(
        AppConstants.batteryPollInterval,
        (_) async {
          try {
            final currentLevel = await _batteryRepo.getBatteryLevel();
            final currentBatteryState = await _batteryRepo.getBatteryState();
            final currentStateString = BatteryRepository.stateToString(currentBatteryState);
            final isChargingNow = currentBatteryState == bp.BatteryState.charging;

            int? estimate;
            if (isChargingNow && currentLevel < 100) {
              _chargeSamples.add(_LevelSample(currentLevel, DateTime.now()));
              estimate = _getEstimate(true, currentLevel);
            } else {
              _chargeSamples.clear();
            }

            // Read temperature
            double? temperature;
            if (isChargingNow || currentBatteryState == bp.BatteryState.full) {
              temperature = await BatteryTemperatureService.getTemperature();
            }

            if (state.state != currentStateString) {
              state = state.copyWith(state: currentStateString, level: currentLevel, estimatedMinutesToFull: estimate, temperatureCelsius: temperature);
            } else {
              state = state.copyWith(level: currentLevel, estimatedMinutesToFull: estimate, temperatureCelsius: temperature);
            }

            unawaited(HomeWidgetService.instance.updateWidget(state, _settingsRepo));

            // Check high temperature alert
            if (temperature != null && temperature > 45.0 && isChargingNow) {
              NotificationService.instance.showTemperatureAlert(temperature);
            }

            _checkThreshold(currentLevel, _previousLevel);
            _checkBatterySaver(currentLevel);

            // Daily summary check
            unawaited(
              BatterySummaryService.instance.checkAndSendSummary(_logRepo, _settingsRepo),
            );

            _previousLevel = currentLevel;

            if (_lastLogTime == null ||
                DateTime.now().difference(_lastLogTime!).inMinutes >=
                    AppConstants.logInterval.inMinutes) {
              LoggerService.instance.info('BatteryNotifier', 'Periodic foreground battery log trigger');
              logBattery();
              _trackChargeCycle(currentLevel, currentStateString);
            }
          } catch (e) {
            LoggerService.instance.error('BatteryNotifier', 'Poll error', e);
          }
        },
      );

      logBattery();
      _trackChargeCycle(level, stateString);
    } catch (e) {
      LoggerService.instance.error('BatteryNotifier', 'Init failed', e);
      state = state.copyWith(isLoading: false, error: 'Failed to read battery info');
    }
  }

  Future<void> _loadHealth() async {
    try {
      final repo = _logRepo;
      final health = await repo.estimateHealthPercent();
      _previousHealthMax = health;
      state = state.copyWith(healthPercent: health);
    } catch (_) {}
  }

  Future<void> logBattery() async {
    if (state.isLoading || state.error != null) {
      LoggerService.instance.debug('BatteryNotifier', 'Skipping log: isLoading=${state.isLoading}, error=${state.error}');
      return;
    }

    final temp = state.temperatureCelsius;
    await _logRepo.addLog(BatteryLog(
      batteryLevel: state.level,
      batteryState: state.state,
      timestamp: DateTime.now(),
      temperatureCelsius: temp,
    ));
    _lastLogTime = DateTime.now();
    LoggerService.instance.debug('BatteryNotifier', 'Battery logged: ${state.level}%, ${state.state}');

    // Record health degradation when battery is full or near-full
    if (state.level >= 95) {
      await _logRepo.addHealthRecord(BatteryHealthRecord(
        timestamp: DateTime.now(),
        maxLevel: state.level,
        temperature: temp,
      ));
      if (state.level > (_previousHealthMax ?? 0)) {
        _previousHealthMax = state.level;
        state = state.copyWith(healthPercent: state.level);
      }
    }
  }

  Future<void> _trackChargeCycle(int level, String stateStr) async {
    if (stateStr != 'Charging' && stateStr != 'Full') return;

    final previousLevel = _previousLevel;
    if (previousLevel == null || previousLevel < 0 || previousLevel > 100) {
      LoggerService.instance.debug('BatteryNotifier', 'Charge cycle: skipping, invalid previousLevel=$previousLevel');
      return;
    }

    final diff = level - previousLevel;
    if (diff > 0) {
      final accumulator = _settingsRepo.getPartialChargeAccumulator() + diff / 100.0;
      if (accumulator >= 1.0) {
        final cycles = _settingsRepo.getChargeCycleCount() + 1;
        await _settingsRepo.setChargeCycleCount(cycles);
        await _settingsRepo.setPartialChargeAccumulator(accumulator - 1.0);
        state = state.copyWith(chargeCycleCount: cycles);
        LoggerService.instance.info('BatteryNotifier', 'Charge cycle completed: $cycles total');
      } else {
        await _settingsRepo.setPartialChargeAccumulator(accumulator);
      }
    } else if (diff < 0) {
      LoggerService.instance.debug('BatteryNotifier', 'Charge cycle: level decreased $previousLevel -> $level, no partial');
    }
  }

  Future<void> _checkBatterySaver(int level) async {
    if (!_settingsRepo.isBatterySaverEnabled()) return;
    if (_saverNotifiedForCurrentCharge) return;

    final batteryState = await _batteryRepo.getBatteryState();
    if (batteryState != bp.BatteryState.charging && batteryState != bp.BatteryState.full) return;

    if (level >= AppConstants.batterySaverThreshold) {
      _saverNotifiedForCurrentCharge = true;
      state = state.copyWith(batterySaverActive: true);
      NotificationService.instance.showBatterySaverSuggestion(level);
      LoggerService.instance.info('BatteryNotifier', 'Battery saver: level=$level reached threshold, notification sent');
    }
  }

  int? _getEstimate(bool isCharging, int level) {
    if (!isCharging || level >= 100) return null;
    if (_chargeSamples.length >= 2) {
      return _estimateTimeToFull(level);
    }
    final cachedRate = _settingsRepo.getCachedChargeRate();
    if (cachedRate != null && cachedRate > 0) {
      final remaining = (100 - level) / cachedRate;
      return remaining.round();
    }
    return null;
  }

  int? _estimateTimeToFull(int currentLevel) {
    if (_chargeSamples.length < 2) return null;
    final first = _chargeSamples.first;
    final last = _chargeSamples.last;
    final levelDiff = last.level - first.level;
    final minutesDiff = last.timestamp.difference(first.timestamp).inMinutes.toDouble();
    if (levelDiff <= 0 || minutesDiff <= 0) return null;
    final ratePerMinute = levelDiff / minutesDiff;

    unawaited(
      _settingsRepo.setCachedChargeRate(ratePerMinute).catchError((e) {
        LoggerService.instance.error('BatteryNotifier', 'Failed to cache charge rate', e);
      }),
    );

    final remaining = (100 - currentLevel) / ratePerMinute;
    return remaining.round();
  }

  Future<void> _checkThreshold(int level, int? previousLevel) async {
    final threshold = _settingsRepo.getThreshold();
    final alertEnabled = _settingsRepo.isAlertEnabled();
    final alarmEnabled = _settingsRepo.isAlarmEnabled();
    final quietHoursActive = _settingsRepo.isCurrentlyQuietHours();

    if (quietHoursActive) return;

    if (level < threshold) {
      _alertSentForCurrentCharge = false;
      _alarmSentForCurrentCharge = false;
      return;
    }

    if (previousLevel != null && previousLevel < threshold) {
      if (alertEnabled && !_alertSentForCurrentCharge) {
        await NotificationService.instance.showThresholdAlert(level);
        _alertSentForCurrentCharge = true;
      }

      if (alarmEnabled && !_alarmSentForCurrentCharge) {
        await NotificationService.instance.showAlarm(level);
        _alarmSentForCurrentCharge = true;
      }
    }
  }

  Future<void> _handleSessionTracking(String stateStr, int currentLevel) async {
    final prefs = await SharedPreferences.getInstance();
    
    final isPluggedIn = stateStr == 'Charging' || stateStr == 'Full';
    final wasPluggedIn = _previousBatteryState == 'Charging' || _previousBatteryState == 'Full';

    if (isPluggedIn && !wasPluggedIn) {
      // Plugged in
      await prefs.setString(AppConstants.chargingSessionStartTimeKey, DateTime.now().toIso8601String());
      await prefs.setInt(AppConstants.chargingSessionStartLevelKey, currentLevel);
    } else if (!isPluggedIn && wasPluggedIn) {
      // Unplugged
      final startTimeStr = prefs.getString(AppConstants.chargingSessionStartTimeKey);
      final startLevel = prefs.getInt(AppConstants.chargingSessionStartLevelKey);
      
      if (startTimeStr != null && startLevel != null) {
        final startTime = DateTime.tryParse(startTimeStr);
        if (startTime != null) {
          final session = ChargingSession(
            startTime: startTime,
            endTime: DateTime.now(),
            startLevel: startLevel,
            endLevel: currentLevel,
          );
          if (session.duration.inMinutes >= 1) {
            await _chargingSessionDb.addSession(session);
          }
        }
      }
      
      await prefs.remove(AppConstants.chargingSessionStartTimeKey);
      await prefs.remove(AppConstants.chargingSessionStartLevelKey);
    }
  }
}

final batteryProvider = NotifierProvider<BatteryNotifier, BatteryState>(() {
  return BatteryNotifier();
});

class _LevelSample {
  final int level;
  final DateTime timestamp;
  _LevelSample(this.level, this.timestamp);
}
