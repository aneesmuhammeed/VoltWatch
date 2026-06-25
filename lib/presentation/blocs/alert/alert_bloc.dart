import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voltwatch/core/providers/providers.dart';
import 'package:voltwatch/core/services/alarm_player_service.dart';
import 'package:voltwatch/core/services/logger_service.dart';
import 'package:voltwatch/core/services/notification_service.dart';
import 'package:voltwatch/data/repositories/settings_repository.dart';
import 'alert_state.dart';

class AlertNotifier extends Notifier<AlertState> {
  late final SettingsRepository _settingsRepo;

  @override
  AlertState build() {
    _settingsRepo = ref.watch(settingsRepositoryProvider);
    
    // Initial async check for permissions / load configuration
    Future.microtask(() => loadAlertSettings());

    return const AlertState(isLoading: true);
  }

  Future<void> loadAlertSettings() async {
    final status = await Permission.notification.status;
    final isPermissionGranted = status.isGranted;
    
    final savedAlertEnabled = _settingsRepo.isAlertEnabled();
    final savedAlarmEnabled = _settingsRepo.isAlarmEnabled();
    
    final isAlertEnabled = isPermissionGranted && savedAlertEnabled;
    final isAlarmEnabled = isPermissionGranted && savedAlarmEnabled;

    String? error;
    if (!isPermissionGranted && (savedAlertEnabled || savedAlarmEnabled)) {
      error = 'Notification permission has been revoked. Please enable in Settings.';
    }

    state = state.copyWith(
      threshold: _settingsRepo.getThreshold(),
      isEnabled: isAlertEnabled,
      isAlarmEnabled: isAlarmEnabled,
      selectedSoundUrl: _settingsRepo.getAlarmSound(),
      isLoading: false,
      errorMessage: error,
      errorNonce: error != null ? state.errorNonce + 1 : state.errorNonce,
    );
    
    LoggerService.instance.info('AlertNotifier', 'Loaded: threshold=${state.threshold}, alerts=$isAlertEnabled, alarms=$isAlarmEnabled, permissionGranted=$isPermissionGranted');
  }

  Future<void> setThreshold(int threshold) async {
    await _settingsRepo.setThreshold(threshold);
    state = state.copyWith(threshold: threshold);
  }

  Future<void> toggleAlerts(bool enabled) async {
    if (enabled) {
      final status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        state = state.copyWith(
          errorMessage: 'Notification permission permanently denied. Enable in Settings.',
          errorNonce: state.errorNonce + 1,
        );
        return;
      }
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return;
    }
    await _settingsRepo.setAlertEnabled(enabled);
    state = state.copyWith(isEnabled: enabled);
    LoggerService.instance.info('AlertNotifier', 'Alert toggled: $enabled');
  }

  Future<void> toggleAlarm(bool enabled) async {
    if (enabled) {
      final status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        state = state.copyWith(
          errorMessage: 'Notification permission permanently denied. Enable in Settings.',
          errorNonce: state.errorNonce + 1,
        );
        return;
      }
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return;
    }
    await _settingsRepo.setAlarmEnabled(enabled);
    state = state.copyWith(isAlarmEnabled: enabled);
    LoggerService.instance.info('AlertNotifier', 'Alarm toggled: $enabled');
  }

  Future<void> testAlarm() async {
    LoggerService.instance.info('AlertNotifier', 'Testing alarm...');
    await NotificationService.instance.showAlarm(state.threshold);
  }

  Future<void> changeAlarmSound(String soundUrl) async {
    await _settingsRepo.setAlarmSound(soundUrl);
    state = state.copyWith(selectedSoundUrl: soundUrl);
    await AlarmPlayerService.instance.playPreview(soundUrl);
  }
}

final alertProvider = NotifierProvider<AlertNotifier, AlertState>(() {
  return AlertNotifier();
});
