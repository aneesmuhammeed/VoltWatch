class BatteryInsights {
  final int highest;
  final int lowest;
  final int average;
  final double drainRatePerHour;
  final double? avgTemperature;

  const BatteryInsights({
    required this.highest,
    required this.lowest,
    required this.average,
    required this.drainRatePerHour,
    this.avgTemperature,
  });
}