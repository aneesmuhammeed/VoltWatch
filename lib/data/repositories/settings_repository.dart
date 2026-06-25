import 'package:voltwatch/data/datasources/settings_local.dart';

class SettingsRepository {
  final SettingsLocalDatasource _localDatasource;

  SettingsRepository(this._localDatasource);

  int getThreshold() => _localDatasource.getThreshold();
  Future<void> setThreshold(int value) => _localDatasource.setThreshold(value);

  bool isAlertEnabled() => _localDatasource.isAlertEnabled();
  Future<void> setAlertEnabled(bool enabled) =>
      _localDatasource.setAlertEnabled(enabled);

  bool isAlarmEnabled() => _localDatasource.isAlarmEnabled();
  Future<void> setAlarmEnabled(bool enabled) =>
      _localDatasource.setAlarmEnabled(enabled);

  String getThemeMode() => _localDatasource.getThemeMode();
  Future<void> setThemeMode(String mode) => _localDatasource.setThemeMode(mode);

  double? getCachedChargeRate() => _localDatasource.getCachedChargeRate();
  Future<void> setCachedChargeRate(double value) => _localDatasource.setCachedChargeRate(value);

  String getAlarmSound() => _localDatasource.getAlarmSound();
  Future<void> setAlarmSound(String url) => _localDatasource.setAlarmSound(url);

  bool isQuietHoursEnabled() => _localDatasource.isQuietHoursEnabled();
  Future<void> setQuietHoursEnabled(bool enabled) =>
      _localDatasource.setQuietHoursEnabled(enabled);

  String getQuietHoursStart() => _localDatasource.getQuietHoursStart();
  Future<void> setQuietHoursStart(String time) =>
      _localDatasource.setQuietHoursStart(time);

  String getQuietHoursEnd() => _localDatasource.getQuietHoursEnd();
  Future<void> setQuietHoursEnd(String time) =>
      _localDatasource.setQuietHoursEnd(time);

  bool isCurrentlyQuietHours() => _localDatasource.isCurrentlyQuietHours();

  bool isBatterySaverEnabled() => _localDatasource.isBatterySaverEnabled();
  Future<void> setBatterySaverEnabled(bool enabled) => _localDatasource.setBatterySaverEnabled(enabled);

  bool isSummaryNotificationEnabled() => _localDatasource.isSummaryNotificationEnabled();
  Future<void> setSummaryNotificationEnabled(bool enabled) => _localDatasource.setSummaryNotificationEnabled(enabled);

  int getSummaryNotificationHour() => _localDatasource.getSummaryNotificationHour();
  Future<void> setSummaryNotificationHour(int hour) => _localDatasource.setSummaryNotificationHour(hour);

  int getChargeCycleCount() => _localDatasource.getChargeCycleCount();
  Future<void> setChargeCycleCount(int count) => _localDatasource.setChargeCycleCount(count);
  double getPartialChargeAccumulator() => _localDatasource.getPartialChargeAccumulator();
  Future<void> setPartialChargeAccumulator(double value) => _localDatasource.setPartialChargeAccumulator(value);
}
