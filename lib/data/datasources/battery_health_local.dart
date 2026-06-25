import 'package:hive/hive.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/data/models/battery_health_record.dart';

class BatteryHealthLocalDatasource {
  Box<BatteryHealthRecord>? _cachedBox;

  Future<Box<BatteryHealthRecord>> _getBox() async {
    if (_cachedBox != null && _cachedBox!.isOpen) return _cachedBox!;
    if (Hive.isBoxOpen(AppConstants.batteryHealthBoxName)) {
      _cachedBox = Hive.box<BatteryHealthRecord>(AppConstants.batteryHealthBoxName);
    } else {
      _cachedBox = await Hive.openBox<BatteryHealthRecord>(AppConstants.batteryHealthBoxName);
    }
    return _cachedBox!;
  }

  Future<void> addRecord(BatteryHealthRecord record) async {
    final box = await _getBox();
    await box.add(record);

    // Cleanup old records (older than 30 days) to prevent database growth
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
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

  Future<List<BatteryHealthRecord>> getAllRecords() async {
    final box = await _getBox();
    return box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<BatteryHealthRecord?> getLatestRecord() async {
    final records = await getAllRecords();
    return records.isNotEmpty ? records.first : null;
  }

  /// Estimates battery health % based on the average of recent peak charge levels.
  Future<int> estimateHealthPercent() async {
    final records = await getAllRecords();
    if (records.isEmpty) return 100;
    final recentRecords = records.length > 30 ? records.sublist(0, 30) : records;
    if (recentRecords.isEmpty) return 100;
    final topLevels = recentRecords.map((r) => r.maxLevel).toList()
      ..sort((a, b) => b.compareTo(a));
    final topCount = (topLevels.length * 0.3).ceil().clamp(1, topLevels.length);
    final topLevelsSubset = topLevels.sublist(0, topCount);
    final avgPeak = topLevelsSubset.reduce((a, b) => a + b) ~/ topLevelsSubset.length;
    return avgPeak.clamp(0, 100);
  }
}
