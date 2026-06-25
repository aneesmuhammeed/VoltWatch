import 'package:flutter/material.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/utils/date_formatter.dart';
import 'package:voltwatch/data/models/battery_log.dart';

/// A single row in the analytics log list.
class BatteryLogTile extends StatelessWidget {
  final BatteryLog log;

  const BatteryLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.batteryColor(log.batteryLevel);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          '${log.batteryLevel}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(
        '${log.batteryLevel}% — ${log.batteryState}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(DateFormatter.relative(log.timestamp)),
      trailing: Text(
        DateFormatter.time(log.timestamp),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
