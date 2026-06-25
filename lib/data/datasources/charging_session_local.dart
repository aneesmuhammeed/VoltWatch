import 'package:hive/hive.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/data/models/charging_session.dart';

class ChargingSessionLocalDatasource {
  Box<ChargingSession>? _cachedBox;

  Future<Box<ChargingSession>> _getBox() async {
    if (_cachedBox != null && _cachedBox!.isOpen) return _cachedBox!;
    if (Hive.isBoxOpen(AppConstants.chargingSessionBoxName)) {
      _cachedBox = Hive.box<ChargingSession>(AppConstants.chargingSessionBoxName);
    } else {
      _cachedBox = await Hive.openBox<ChargingSession>(AppConstants.chargingSessionBoxName);
    }
    return _cachedBox!;
  }

  Future<void> addSession(ChargingSession session) async {
    final box = await _getBox();
    await box.add(session);

    // Cleanup old sessions (older than 30 days) to prevent infinite database growth
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final keysToDelete = <dynamic>[];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item.endTime.isBefore(cutoff)) {
        keysToDelete.add(key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }

  Future<List<ChargingSession>> getAllSessions() async {
    final box = await _getBox();
    return box.values.toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime)); // newest first
  }
}
