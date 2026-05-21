import 'package:dio/dio.dart';

abstract class AttendanceRemoteDataSource {
  Future<Map<String, dynamic>> getAttendance({List<int>? salesPersonIds});
  Future<Map<String, dynamic>> getTodayAttendance();
  Future<Map<String, dynamic>> postAttendance({required String attendanceDatetime,required int flag,required String locationName,String? note,String? filePath,required int nikNumber});
  Future<Map<String, dynamic>> postAttendanceActivity({required String attendanceDatetime,  required int flag,  required String locationName,  String? note,  required List<String> filePaths, required int nikNumber});
  Future<Map<String, dynamic>> getLocations();
  Future<Map<String, dynamic>> getOfficeLocations();
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final Dio dio;

  AttendanceRemoteDataSourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> getLocations() async {
    final response = await dio.get('/attendance/locations');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getOfficeLocations() async {
    final response = await dio.get('/attendance/locations/office');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getTodayAttendance() async {
    final response = await dio.get('/attendance/today');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getAttendance({List<int>? salesPersonIds}) async {
    final response = await dio.get(
      '/attendance',
      queryParameters: {
        "per_page": 10,
        if (salesPersonIds != null && salesPersonIds.isNotEmpty)
          "sales_person_id": salesPersonIds.join(','),
      },
    );

    return response.data;
  }

  @override
  Future<Map<String, dynamic>> postAttendance({  required String attendanceDatetime,  required int flag,  required String locationName,  String? note,  String? filePath, required int nikNumber}) async {
    final formData = FormData.fromMap({
      'attendance_datetime': attendanceDatetime,
      'flag': flag,
      'location_name': locationName,
      'nik_number': nikNumber,
      if (note != null) 'note': note,
      if (filePath != null)
        'file_attachment': await MultipartFile.fromFile(filePath),
    });

    final response = await dio.post('/attendance', data: formData);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> postAttendanceActivity({  required String attendanceDatetime,  required int flag,  required String locationName,  String? note,  required List<String> filePaths, required int nikNumber}) async {
    final formData = FormData.fromMap({
      'attendance_datetime': attendanceDatetime,
      'flag': flag,
      'location_name': locationName,
      if (note != null) 'note': note,
    });

    for (var path in filePaths) {
      formData.files.add(MapEntry(
        'files[]',
        await MultipartFile.fromFile(path),
      ));
    }

    final response = await dio.post('/attendance/activity', data: formData);
    return response.data;
  }
}