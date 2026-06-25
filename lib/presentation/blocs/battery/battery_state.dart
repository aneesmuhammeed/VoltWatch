class _Sentinel {
  const _Sentinel();
}

class BatteryState {
  final int level;
  final String state;
  final bool isLoading;
  final String? error;
  final int? estimatedMinutesToFull;

  // Smart Charging / Battery Saver
  final bool batterySaverEnabled;
  final bool batterySaverActive;

  // Temperature
  final double? temperatureCelsius;

  // Health degradation
  final int healthPercent;

  // Charge cycle
  final int chargeCycleCount;

  const BatteryState({
    this.level = 0,
    this.state = 'Unknown',
    this.isLoading = true,
    this.error,
    this.estimatedMinutesToFull,
    this.batterySaverEnabled = false,
    this.batterySaverActive = false,
    this.temperatureCelsius,
    this.healthPercent = 100,
    this.chargeCycleCount = 0,
  });

  bool get isCharging => state == 'Charging';
  bool get isFull => state == 'Full';

  static const _clearEstimate = _Sentinel();

  BatteryState copyWith({
    int? level,
    String? state,
    bool? isLoading,
    String? error,
    Object? estimatedMinutesToFull = _clearEstimate,
    bool? batterySaverEnabled,
    bool? batterySaverActive,
    double? temperatureCelsius,
    int? healthPercent,
    int? chargeCycleCount,
  }) {
    return BatteryState(
      level: level ?? this.level,
      state: state ?? this.state,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      estimatedMinutesToFull: identical(estimatedMinutesToFull, _clearEstimate)
          ? this.estimatedMinutesToFull
          : estimatedMinutesToFull as int?,
      batterySaverEnabled: batterySaverEnabled ?? this.batterySaverEnabled,
      batterySaverActive: batterySaverActive ?? this.batterySaverActive,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      healthPercent: healthPercent ?? this.healthPercent,
      chargeCycleCount: chargeCycleCount ?? this.chargeCycleCount,
    );
  }
}
