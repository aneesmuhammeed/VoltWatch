import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/services/logger_service.dart';

class SettingsLocalDatasource {
  final SharedPreferences _prefs;

  SettingsLocalDatasource(this._prefs);

  int getThreshold() {
    return _prefs.getInt(AppConstants.thresholdKey) ??
        AppConstants.defaultThreshold;
  }

  Future<void> setThreshold(int value) async {
    await _prefs.setInt(AppConstants.thresholdKey, value);
    LoggerService.instance.info('SettingsLocal', 'Threshold set to $value%');
  }

  bool isAlertEnabled() {
    return _prefs.getBool(AppConstants.alertEnabledKey) ?? true;
  }

  Future<void> setAlertEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.alertEnabledKey, enabled);
    LoggerService.instance.info('SettingsLocal', 'Alert enabled: $enabled');
  }

  bool isAlarmEnabled() {
    return _prefs.getBool(AppConstants.alarmEnabledKey) ?? false;
  }

  Future<void> setAlarmEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.alarmEnabledKey, enabled);
    LoggerService.instance.info('SettingsLocal', 'Alarm enabled: $enabled');
  }

  String getThemeMode() {
    return _prefs.getString(AppConstants.themeModeKey) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(AppConstants.themeModeKey, mode);
    LoggerService.instance.info('SettingsLocal', 'Theme mode: $mode');
  }

  double? getCachedChargeRate() {
    return _prefs.getDouble(AppConstants.cachedChargeRateKey);
  }

  Future<void> setCachedChargeRate(double value) async {
    await _prefs.setDouble(AppConstants.cachedChargeRateKey, value);
    LoggerService.instance.info('SettingsLocal', 'Cached charge rate set to: $value');
  }

  String getAlarmSound() {
    return _prefs.getString(AppConstants.alarmSoundKey) ??
        AppConstants.alarmSounds.first['url']!;
  }

  Future<void> setAlarmSound(String url) async {
    await _prefs.setString(AppConstants.alarmSoundKey, url);
    LoggerService.instance.info('SettingsLocal', 'Alarm sound set to: $url');
  }

  bool isQuietHoursEnabled() {
    return _prefs.getBool(AppConstants.quietHoursEnabledKey) ?? false;
  }

  Future<void> setQuietHoursEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.quietHoursEnabledKey, enabled);
    LoggerService.instance.info('SettingsLocal', 'Quiet hours enabled: $enabled');
  }

  String getQuietHoursStart() {
    return _prefs.getString(AppConstants.quietHoursStartKey) ?? '22:00';
  }

  Future<void> setQuietHoursStart(String time) async {
    await _prefs.setString(AppConstants.quietHoursStartKey, time);
    LoggerService.instance.info('SettingsLocal', 'Quiet hours start: $time');
  }

  String getQuietHoursEnd() {
    return _prefs.getString(AppConstants.quietHoursEndKey) ?? '08:00';
  }

  Future<void> setQuietHoursEnd(String time) async {
    await _prefs.setString(AppConstants.quietHoursEndKey, time);
    LoggerService.instance.info('SettingsLocal', 'Quiet hours end: $time');
  }

  bool isCurrentlyQuietHours() {
    if (!isQuietHoursEnabled()) return false;

    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return AppConstants.isTimeInQuietHours(currentTime, getQuietHoursStart(), getQuietHoursEnd());
  }

  // Battery Saver Mode
  bool isBatterySaverEnabled() {
    return _prefs.getBool(AppConstants.batterySaverEnabledKey) ?? false;
  }

  Future<void> setBatterySaverEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.batterySaverEnabledKey, enabled);
    LoggerService.instance.info('SettingsLocal', 'Battery saver mode: $enabled');
  }

  // Daily Summary Notification
  bool isSummaryNotificationEnabled() {
    return _prefs.getBool(AppConstants.summaryNotificationEnabledKey) ?? false;
  }

  Future<void> setSummaryNotificationEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.summaryNotificationEnabledKey, enabled);
    LoggerService.instance.info('SettingsLocal', 'Summary notification: $enabled');
  }

  int getSummaryNotificationHour() {
    return _prefs.getInt(AppConstants.summaryNotificationHourKey) ?? AppConstants.defaultSummaryHour;
  }

  Future<void> setSummaryNotificationHour(int hour) async {
    await _prefs.setInt(AppConstants.summaryNotificationHourKey, hour);
    LoggerService.instance.info('SettingsLocal', 'Summary notification hour: $hour');
  }

  // Charge cycle counter
  int getChargeCycleCount() {
    return _prefs.getInt(AppConstants.chargeCycleCountKey) ?? 0;
  }

  Future<void> setChargeCycleCount(int count) async {
    await _prefs.setInt(AppConstants.chargeCycleCountKey, count);
  }

  double getPartialChargeAccumulator() {
    return _prefs.getDouble(AppConstants.partialChargeKey) ?? 0.0;
  }

  Future<void> setPartialChargeAccumulator(double value) async {
    await _prefs.setDouble(AppConstants.partialChargeKey, value);
  }
}
