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




  static AttendanceLocationModel? fromJson(Map<String, dynamic> json) {
    final rawId = json['location_id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (id == null) return null;

    return AttendanceLocationModel(
      id: id,
      name: json['location_name'] ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      radius: json['radius_meter'],
      typeLocationId: json['type_location_id'],
    );
  }
}
