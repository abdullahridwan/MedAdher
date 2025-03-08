part of '../main.dart';

@HiveType(typeId: 1)
class MedicationLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String medicationId;

  @HiveField(2)
  final String date;

  @HiveField(3)
  bool taken;

  @HiveField(4)
  String note;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.date,
    required this.taken,
    required this.note,
  });
}

class MedicationLogAdapter extends TypeAdapter<MedicationLog> {
  @override
  final int typeId = 1;

  @override
  MedicationLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationLog(
      id: fields[0] as String,
      medicationId: fields[1] as String,
      date: fields[2] as String,
      taken: fields[3] as bool,
      note: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicationId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.taken)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
