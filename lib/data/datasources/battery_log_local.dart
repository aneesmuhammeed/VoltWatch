import 'package:hive/hive.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/data/models/battery_log.dart';

/// Handles all Hive read/write operations for battery logs.
class BatteryLogLocalDatasource {
  Box<BatteryLog>? _cachedBox;

  Future<Box<BatteryLog>> _getBox() async {
    if (_cachedBox != null && _cachedBox!.isOpen) return _cachedBox!;
    if (Hive.isBoxOpen(AppConstants.batteryLogBoxName)) {
      _cachedBox = Hive.box<BatteryLog>(AppConstants.batteryLogBoxName);
    } else {
      _cachedBox = await Hive.openBox<BatteryLog>(AppConstants.batteryLogBoxName);
    }
    return _cachedBox!;
  }

  Future<void> addLog(BatteryLog log) async {
    final box = await _getBox();
    await box.add(log);

    // Cleanup old logs (older than 7 days) to prevent infinite database growth
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final keysToDelete = <dynamic>[];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item.timestamp.isBefore(cutoff)) {
        keysToDelete.add(key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }

  Future<List<BatteryLog>> getAllLogs() async {
    final box = await _getBox();
    return box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first
  }

  /// Returns logs from the last [hours] hours.
  Future<List<BatteryLog>> getLogsSince(Duration duration) async {
    final cutoff = DateTime.now().subtract(duration);
    final all = await getAllLogs();
    return all.where((log) => log.timestamp.isAfter(cutoff)).toList();
  }

  /// Returns today's logs for insights calculation.
  Future<List<BatteryLog>> getTodayLogs() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final all = await getAllLogs();
    return all.where((log) => log.timestamp.isAfter(startOfDay)).toList();
  }

  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
}
