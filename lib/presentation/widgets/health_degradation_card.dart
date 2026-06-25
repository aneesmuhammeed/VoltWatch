import 'package:flutter/material.dart';

class HealthDegradationCard extends StatelessWidget {
  final int healthPercent;
  final int chargeCycleCount;

  const HealthDegradationCard({
    super.key,
    required this.healthPercent,
    required this.chargeCycleCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color healthColor;
    String healthLabel;
    if (healthPercent >= 95) {
      healthColor = Colors.green;
      healthLabel = 'Excellent';
    } else if (healthPercent >= 85) {
      healthColor = Colors.lightGreen;
      healthLabel = 'Good';
    } else if (healthPercent >= 75) {
      healthColor = Colors.amber;
      healthLabel = 'Fair';
    } else if (healthPercent >= 60) {
      healthColor = Colors.orange;
      healthLabel = 'Degraded';
    } else {
      healthColor = Colors.red;
      healthLabel = 'Poor';
    }

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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: healthPercent / 100,
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
                      '$healthPercent%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: healthColor,
                          ),
                    ),
                    Text(
                      healthLabel,
                      style: TextStyle(fontSize: 12, color: healthColor),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$chargeCycleCount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Charge cycles',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
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
