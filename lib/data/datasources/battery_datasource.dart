import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

/// Thin wrapper around battery_plus to keep platform dependency
/// contained in the data layer.
class BatteryDatasource {
  final Battery _battery = Battery();

  Future<int> getBatteryLevel() => _battery.batteryLevel;

  Future<BatteryState> getBatteryState() => _battery.batteryState;

  /// Emits whenever charging state changes (plug in / unplug).
  Stream<BatteryState> get onBatteryStateChanged =>
      _battery.onBatteryStateChanged;
}
