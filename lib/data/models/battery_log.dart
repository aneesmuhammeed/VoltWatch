import 'package:hive/hive.dart';

class BatteryLog extends HiveObject {
  final int batteryLevel;
  final String batteryState;
  final DateTime timestamp;
  final double? temperatureCelsius;

  BatteryLog({
    required this.batteryLevel,
    required this.batteryState,
    required this.timestamp,
    this.temperatureCelsius,
  });

  Map<String, dynamic> toJson() => {
        'batteryLevel': batteryLevel,
        'batteryState': batteryState,
        'timestamp': timestamp.toIso8601String(),
        'temperatureCelsius': temperatureCelsius,
      };

  factory BatteryLog.fromJson(Map<String, dynamic> json) => BatteryLog(
        batteryLevel: (json['batteryLevel'] as num?)?.toInt() ?? 0,
        batteryState: (json['batteryState'] as String?) ?? 'Unknown',
        timestamp: (json['timestamp'] is String)
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
      );
}

class BatteryLogAdapter extends TypeAdapter<BatteryLog> {
  @override
  final int typeId = 0;

  @override
  BatteryLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BatteryLog(
      batteryLevel: fields[0] as int,
      batteryState: fields[1] as String,
      timestamp: fields[2] as DateTime,
      temperatureCelsius: fields[3] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, BatteryLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.batteryLevel)
      ..writeByte(1)
      ..write(obj.batteryState)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.temperatureCelsius);
  }
}
