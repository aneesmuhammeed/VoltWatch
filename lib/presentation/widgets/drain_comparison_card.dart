import 'package:flutter/material.dart';

class DrainComparisonCard extends StatelessWidget {
  final double screenOnDrain;
  final double bgDrain;

  const DrainComparisonCard({
    super.key,
    required this.screenOnDrain,
    required this.bgDrain,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Drain Comparison', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(context, 'Screen On', '${screenOnDrain.toStringAsFixed(1)}%/hr', Icons.phone_android),
                ),
                Container(height: 40, width: 1, color: Theme.of(context).dividerColor),
                Expanded(
                  child: _buildMetric(context, 'Background', '${bgDrain.toStringAsFixed(1)}%/hr', Icons.aod),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
