import 'package:hive/hive.dart';

class ChargingSession extends HiveObject {
  final DateTime startTime;
  final DateTime endTime;
  final int startLevel;
  final int endLevel;

  ChargingSession({
    required this.startTime,
    required this.endTime,
    required this.startLevel,
    required this.endLevel,
  });

  Duration get duration => endTime.difference(startTime);
  int get levelGained => endLevel - startLevel;
}

class ChargingSessionAdapter extends TypeAdapter<ChargingSession> {
  @override
  final int typeId = 2;

  @override
  ChargingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChargingSession(
      startTime: fields[0] as DateTime,
      endTime: fields[1] as DateTime,
      startLevel: fields[2] as int,
      endLevel: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ChargingSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.endTime)
      ..writeByte(2)
      ..write(obj.startLevel)
      ..writeByte(3)
      ..write(obj.endLevel);
  }
}
