import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:voltwatch/data/datasources/battery_datasource.dart';

/// Provides real-time battery data to BLoCs.
/// Combines level polling with state-change stream.
class BatteryRepository {
  final BatteryDatasource _datasource;

  BatteryRepository(this._datasource);

  Future<int> getBatteryLevel() => _datasource.getBatteryLevel();

  Future<BatteryState> getBatteryState() => _datasource.getBatteryState();

  Stream<BatteryState> get onBatteryStateChanged =>
      _datasource.onBatteryStateChanged;

  /// Converts BatteryState enum to a human-readable string for storage/display.
  static String stateToString(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
      case BatteryState.full:
        return 'Full';
      case BatteryState.connectedNotCharging:
        return 'Connected';
      case BatteryState.unknown:
        return 'Discharging';
    }
  }

  /// Parses stored string back to BatteryState enum.
  static BatteryState stringToState(String value) {
    switch (value.toLowerCase()) {
      case 'charging':
        return BatteryState.charging;
      case 'full':
        return BatteryState.full;
      case 'connected':
        return BatteryState.connectedNotCharging;
      case 'discharging':
      case 'unknown':
      default:
        return BatteryState.discharging;
    }
  }
}
