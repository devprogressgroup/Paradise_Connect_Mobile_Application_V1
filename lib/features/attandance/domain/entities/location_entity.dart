class AttendanceLocation {
  final int id;
  final String name;
  final String? latitude;
  final String? longitude;
  final int? radius;

  AttendanceLocation({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.radius,
  });
}
