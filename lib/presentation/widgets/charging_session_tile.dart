import 'package:flutter/material.dart';
import 'package:voltwatch/data/models/charging_session.dart';

class ChargingSessionTile extends StatelessWidget {
  final ChargingSession session;

  const ChargingSessionTile({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final duration = session.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.bolt, color: Colors.amber),
      ),
      title: Text('${session.startLevel}% → ${session.endLevel}% (+${session.levelGained}%)'),
      subtitle: Text('Duration: $durationStr'),
      trailing: Text(
        '${session.endTime.hour.toString().padLeft(2, '0')}:${session.endTime.minute.toString().padLeft(2, '0')}\n${session.endTime.day}/${session.endTime.month}',
        textAlign: TextAlign.right,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
