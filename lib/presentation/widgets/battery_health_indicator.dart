import 'package:flutter/material.dart';

/// Battery health indicator showing battery condition.
class BatteryHealthIndicator extends StatelessWidget {
  final int level;
  final String state;
  final int? estimatedMinutesToFull;

  const BatteryHealthIndicator({
    super.key,
    required this.level,
    required this.state,
    this.estimatedMinutesToFull,
  });

  String _getHealthStatus() {
    if (level >= 80) return 'Excellent';
    if (level >= 60) return 'Good';
    if (level >= 40) return 'Fair';
    if (level >= 20) return 'Low';
    return 'Critical';
  }

  Color _getHealthColor() {
    if (level >= 80) return Colors.green;
    if (level >= 60) return Colors.lightGreen;
    if (level >= 40) return Colors.amber;
    if (level >= 20) return Colors.orange;
    return Colors.red;
  }

  String _getHealthAdvice() {
    if (level >= 80) return 'Battery is in excellent condition';
    if (level >= 60) return 'Battery is performing well';
    if (level >= 40) return 'Consider charging soon';
    if (level >= 20) return 'Battery is low, please charge';
    return 'Battery critically low!';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final health = _getHealthStatus();
    final healthColor = _getHealthColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: healthColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Battery Health',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Health bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: level / 100,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      health,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: healthColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getHealthAdvice(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (state == 'Charging')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.bolt, color: Colors.green, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        'Charging',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
