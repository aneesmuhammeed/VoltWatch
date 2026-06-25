import 'package:flutter/material.dart';

class TemperatureIndicator extends StatelessWidget {
  final double? temperatureCelsius;

  const TemperatureIndicator({super.key, required this.temperatureCelsius});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (temperatureCelsius == null) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.thermostat_outlined, color: colorScheme.onSurfaceVariant),
          title: const Text('Battery Temperature'),
          subtitle: const Text('Not available'),
        ),
      );
    }

    final temp = temperatureCelsius!;
    Color color;
    IconData icon;
    String label;

    if (temp < 30) {
      color = Colors.green;
      icon = Icons.thermostat_auto;
      label = 'Normal';
    } else if (temp < 40) {
      color = Colors.amber;
      icon = Icons.thermostat_auto;
      label = 'Warm';
    } else if (temp < 45) {
      color = Colors.orange;
      icon = Icons.warning_amber_rounded;
      label = 'Hot — monitor';
    } else {
      color = Colors.red;
      icon = Icons.warning;
      label = 'Very hot — unplug!';
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text('Battery Temperature'),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${temp.toStringAsFixed(1)}°C',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
