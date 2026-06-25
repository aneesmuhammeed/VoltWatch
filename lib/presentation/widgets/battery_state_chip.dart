import 'package:flutter/material.dart';

/// Chip displaying the current battery state with an appropriate icon.
class BatteryStateChip extends StatelessWidget {
  final String batteryState;

  const BatteryStateChip({super.key, required this.batteryState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(_iconForState(), size: 18, color: _colorForState(colorScheme)),
      label: Text(
        batteryState,
        style: TextStyle(color: _colorForState(colorScheme)),
      ),
      backgroundColor: _colorForState(colorScheme).withValues(alpha: 0.12),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  IconData _iconForState() {
    switch (batteryState) {
      case 'Charging':
        return Icons.bolt;
      case 'Discharging':
        return Icons.battery_std;
      case 'Full':
        return Icons.battery_full;
      case 'Connected':
        return Icons.power;
      default:
        return Icons.battery_unknown;
    }
  }

  Color _colorForState(ColorScheme scheme) {
    switch (batteryState) {
      case 'Charging':
        return Colors.green;
      case 'Full':
        return Colors.blue;
      case 'Discharging':
        return Colors.orange;
      case 'Connected':
        return Colors.blueGrey;
      default:
        return scheme.onSurfaceVariant;
    }
  }
}
