import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/utils/date_formatter.dart';
import 'package:voltwatch/data/models/battery_log.dart';

/// Line chart displaying battery level over time using fl_chart.
class BatteryChart extends StatelessWidget {
  final List<BatteryLog> logs;

  const BatteryChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data yet')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Reverse so chart reads left-to-right chronologically
    final sortedLogs = List<BatteryLog>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Limit to last 96 data points (24 hours at 15-min intervals) for readability
    final displayLogs = sortedLogs.length > 96
        ? sortedLogs.sublist(sortedLogs.length - 96)
        : sortedLogs;

    final spots = displayLogs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.batteryLevel.toDouble());
    }).toList();

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: 25,
                  getTitlesWidget: (value, _) => Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: _bottomInterval(displayLogs.length),
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= displayLogs.length || index % _bottomInterval(displayLogs.length) != 0) {
                      return const SizedBox.shrink();
                    }
                    // Map the fl_chart index to the actual log entry,
                    // clamping in case of rounding or unexpected values.
                    final safeIndex = index.clamp(0, displayLogs.length - 1);
                    final logEntry = displayLogs[safeIndex];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                      child: Transform.rotate(
                        angle: -0.5, // More rotated to prevent clustering
                        alignment: Alignment.centerLeft,
                        child: Tooltip(
                          message: DateFormatter.dateTime(logEntry.timestamp),
                          child: Text(
                            DateFormatter.time(logEntry.timestamp),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppConstants.batteryHighColor,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 3,
                    color: AppConstants.batteryColor(spot.y.toInt()),
                    strokeWidth: 1.5,
                    strokeColor: colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppConstants.batteryHighColor.withValues(alpha: 0.3),
                      AppConstants.batteryHighColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => colorScheme.inverseSurface,
                getTooltipItems: (spots) => spots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= displayLogs.length) return null;
                  final log = displayLogs[index];
                  return LineTooltipItem(
                    '${log.batteryLevel}%\n${DateFormatter.dateTime(log.timestamp)}',
                    TextStyle(
                      color: colorScheme.onInverseSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _bottomInterval(int count) {
    if (count <= 6) return 1;
    if (count <= 12) return 2;
    if (count <= 24) return 6;
    if (count <= 48) return 12;
    if (count <= 72) return 18;
    return 24;
  }
}
