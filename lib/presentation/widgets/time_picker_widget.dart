import 'package:flutter/material.dart';

/// Time picker widget for selecting hours and minutes.
class TimePickerWidget extends StatefulWidget {
  final String initialTime; // Format: HH:mm
  final ValueChanged<String> onTimeChanged;
  final String label;

  const TimePickerWidget({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    required this.label,
  });

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late String _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  void didUpdateWidget(covariant TimePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTime != widget.initialTime) {
      setState(() {
        _selectedTime = widget.initialTime;
      });
    }
  }

  void _showTimePicker() async {
    TimeOfDay initialTime;
    try {
      final parts = _selectedTime.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          initialTime = TimeOfDay(hour: hour, minute: minute);
        } else {
          initialTime = TimeOfDay.now();
        }
      } else {
        initialTime = TimeOfDay.now();
      }
    } catch (_) {
      initialTime = TimeOfDay.now();
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _selectedTime = newTime);
      widget.onTimeChanged(newTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.label),
      trailing: GestureDetector(
        onTap: _showTimePicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _selectedTime,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
