import 'package:hive/hive.dart';

class BatteryHealthRecord extends HiveObject {
  final DateTime timestamp;
  final int maxLevel;
  final double? temperature;

  BatteryHealthRecord({
    required this.timestamp,
    required this.maxLevel,
    this.temperature,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'maxLevel': maxLevel,
        'temperature': temperature,
      };

  factory BatteryHealthRecord.fromJson(Map<String, dynamic> json) => BatteryHealthRecord(
        timestamp: (json['timestamp'] is String)
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        maxLevel: (json['maxLevel'] as num?)?.toInt() ?? 100,
        temperature: (json['temperature'] as num?)?.toDouble(),
      );
}

class BatteryHealthRecordAdapter extends TypeAdapter<BatteryHealthRecord> {
  @override
  final int typeId = 1;

  @override
  BatteryHealthRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BatteryHealthRecord(
      timestamp: fields.containsKey(0) ? fields[0] as DateTime : DateTime.now(),
      maxLevel: fields.containsKey(1) ? fields[1] as int : 100,
      temperature: fields.containsKey(2) ? fields[2] as double? : null,
    );
  }

  @override
  void write(BinaryWriter writer, BatteryHealthRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.maxLevel)
      ..writeByte(2)
      ..write(obj.temperature);
  }
}
