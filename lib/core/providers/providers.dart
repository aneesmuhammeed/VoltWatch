import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltwatch/data/datasources/battery_datasource.dart';
import 'package:voltwatch/data/datasources/battery_log_local.dart';
import 'package:voltwatch/data/datasources/charging_session_local.dart';
import 'package:voltwatch/data/datasources/settings_local.dart';
import 'package:voltwatch/data/repositories/battery_log_repository.dart';
import 'package:voltwatch/data/repositories/battery_repository.dart';
import 'package:voltwatch/data/repositories/settings_repository.dart';

// Provider for SharedPreferences - initialized at startup
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

// Datasources
final settingsLocalDatasourceProvider = Provider<SettingsLocalDatasource>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return SettingsLocalDatasource(sharedPreferences);
});

final batteryDatasourceProvider = Provider<BatteryDatasource>((ref) {
  return BatteryDatasource();
});

final batteryLogLocalDatasourceProvider = Provider<BatteryLogLocalDatasource>((ref) {
  return BatteryLogLocalDatasource();
});

final chargingSessionLocalDatasourceProvider = Provider<ChargingSessionLocalDatasource>((ref) {
  return ChargingSessionLocalDatasource();
});

// Repositories
final batteryRepositoryProvider = Provider<BatteryRepository>((ref) {
  final datasource = ref.watch(batteryDatasourceProvider);
  return BatteryRepository(datasource);
});

final batteryLogRepositoryProvider = Provider<BatteryLogRepository>((ref) {
  final datasource = ref.watch(batteryLogLocalDatasourceProvider);
  return BatteryLogRepository(datasource);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final datasource = ref.watch(settingsLocalDatasourceProvider);
  return SettingsRepository(datasource);
});
