import 'package:progress_group/features/attandance/domain/entities/location_entity.dart';

class AttendanceLocationModel extends AttendanceLocation {
  AttendanceLocationModel({
    required super.id,
    required super.name,
    super.latitude,
    super.longitude,
    super.radius,
    super.typeLocationId,
  });

  factory AttendanceLocationModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLocationModel(
      id: json['location_id'],
      name: json['location_name'] ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      radius: json['radius_meter'],
      typeLocationId: json['type_location_id'],
    );
  }
}
