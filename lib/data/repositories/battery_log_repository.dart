import 'package:voltwatch/data/datasources/battery_health_local.dart';
import 'package:voltwatch/data/datasources/battery_log_local.dart';
import 'package:voltwatch/data/models/battery_health_record.dart';
import 'package:voltwatch/data/models/battery_insights.dart';
import 'package:voltwatch/data/models/battery_log.dart';

class BatteryLogRepository {
  final BatteryLogLocalDatasource _localDatasource;
  late final BatteryHealthLocalDatasource _healthDatasource;

  BatteryLogRepository(this._localDatasource) {
    _healthDatasource = BatteryHealthLocalDatasource();
  }

  Future<void> addLog(BatteryLog log) => _localDatasource.addLog(log);

  Future<List<BatteryLog>> getAllLogs() => _localDatasource.getAllLogs();

  Future<List<BatteryLog>> getLogsSince(Duration duration) =>
      _localDatasource.getLogsSince(duration);

  Future<List<BatteryLog>> getTodayLogs() => _localDatasource.getTodayLogs();

  Future<void> clearAll() => _localDatasource.clearAll();

  // Health degradation records
  Future<void> addHealthRecord(BatteryHealthRecord record) =>
      _healthDatasource.addRecord(record);

  Future<BatteryHealthRecord?> getLatestHealthRecord() =>
      _healthDatasource.getLatestRecord();

  Future<int> estimateHealthPercent() =>
      _healthDatasource.estimateHealthPercent();

  Future<BatteryInsights?> getTodayInsights() async {
    final logs = await getTodayLogs();
    if (logs.isEmpty) return null;

    final levels = logs.map((l) => l.batteryLevel).toList();
    final highest = levels.reduce((a, b) => a > b ? a : b);
    final lowest = levels.reduce((a, b) => a < b ? a : b);
    final average = levels.reduce((a, b) => a + b) / levels.length;

    final oldest = logs.last;
    final newest = logs.first;
    final hoursDiff =
        newest.timestamp.difference(oldest.timestamp).inMinutes / 60.0;
    final drainRate = hoursDiff > 0
        ? (oldest.batteryLevel - newest.batteryLevel) / hoursDiff
        : 0.0;

    final temps = logs
        .map((l) => l.temperatureCelsius)
        .where((t) => t != null)
        .cast<double>()
        .toList();

    return BatteryInsights(
      highest: highest,
      lowest: lowest,
      average: average.round(),
      drainRatePerHour: drainRate,
      avgTemperature: temps.isNotEmpty
          ? temps.reduce((a, b) => a + b) / temps.length
          : null,
    );
  }
}
