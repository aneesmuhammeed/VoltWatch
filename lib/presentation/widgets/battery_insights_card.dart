import 'package:flutter/material.dart';
import 'package:voltwatch/data/models/battery_insights.dart';

/// Card showing today's battery insights: highest, lowest, average, drain rate.
class BatteryInsightsCard extends StatelessWidget {
  final BatteryInsights insights;

  const BatteryInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Insights",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InsightTile(
                  icon: Icons.arrow_upward,
                  label: 'Highest',
                  value: '${insights.highest}%',
                  color: Colors.green,
                ),
                _InsightTile(
                  icon: Icons.arrow_downward,
                  label: 'Lowest',
                  value: '${insights.lowest}%',
                  color: Colors.red,
                ),
                _InsightTile(
                  icon: Icons.show_chart,
                  label: 'Average',
                  value: '${insights.average}%',
                  color: Colors.blue,
                ),
                _InsightTile(
                  icon: Icons.trending_down,
                  label: 'Drain/hr',
                  value: '${insights.drainRatePerHour.toStringAsFixed(1)}%',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
