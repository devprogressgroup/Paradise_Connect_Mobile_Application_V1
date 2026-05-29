import 'dart:typed_data';
import 'package:dio/dio.dart';

abstract class AttendanceRemoteDataSource {
  Future<Map<String, dynamic>> getAttendance({List<int>? salesPersonIds, String? startDate, String? endDate, int page = 1, int perPage = 10});
  Future<Map<String, dynamic>> getTodayAttendance();
  Future<Map<String, dynamic>> postAttendance({required String attendanceDatetime, required int flag, required String locationName, String? note, String? filePath, Uint8List? fileBytes, required int nikNumber, int? locationId, String? latitude, String? longitude});
  Future<Map<String, dynamic>> postAttendanceActivity({required String attendanceDatetime, required int flag, required String locationName, String? note, required List<String> filePaths, List<Uint8List>? fileBytesData, required int nikNumber, int? locationId, String? latitude, String? longitude});
  Future<Map<String, dynamic>> getLocations();
  Future<Map<String, dynamic>> getOfficeLocations();
  Future<Map<String, dynamic>> getAttendanceActivity({List<int>? salesPersonIds, String? startDate, String? endDate, String? location, int page, int perPage});
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
  Future<Map<String, dynamic>> getAttendance({List<int>? salesPersonIds, String? startDate, String? endDate, int page = 1, int perPage = 10}) async {
    final response = await dio.get(
      '/attendance',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (salesPersonIds != null && salesPersonIds.isNotEmpty)
          "sales_person_id": salesPersonIds.join(','),
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> postAttendance({required String attendanceDatetime, required int flag, required String locationName, String? note, String? filePath, Uint8List? fileBytes, required int nikNumber, int? locationId, String? latitude, String? longitude}) async {
    try {
      MultipartFile? attachment;
      if (fileBytes != null) {
        attachment = MultipartFile.fromBytes(fileBytes, filename: 'photo.jpg');
      } else if (filePath != null) {
        attachment = await MultipartFile.fromFile(filePath);
      }

      final formData = FormData.fromMap({
        'attendance_datetime': attendanceDatetime,
        'flag': flag,
        'location_name': locationName,
        'nik_number': nikNumber,
        'serial': 'PARADISE CONNECT',
        if (locationId != null) 'location_id': locationId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (note != null) 'note': note,
        if (attachment != null) 'file_attachment': attachment,
      });

      final response = await dio.post('/attendance', data: formData);
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel && e.error == 'SESSION_EXPIRED') throw Exception('SESSION_EXPIRED');
      throw Exception(e.response?.data?['message'] ?? 'Gagal submit attendance');
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendanceActivity({List<int>? salesPersonIds, String? startDate, String? endDate, String? location, int page = 1, int perPage = 20}) async {
    final response = await dio.get(
      '/attendance/activity',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (salesPersonIds != null && salesPersonIds.isNotEmpty)
          'sales_person_id': salesPersonIds.join(','),
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (location != null && location.isNotEmpty) 'location': location,
      },
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> postAttendanceActivity({required String attendanceDatetime, required int flag, required String locationName, String? note, required List<String> filePaths, List<Uint8List>? fileBytesData, required int nikNumber, int? locationId, String? latitude, String? longitude}) async {
    try {
      final formData = FormData.fromMap({
        'attendance_datetime': attendanceDatetime,
        'flag': flag,
        'location_name': locationName,
        'nik_number': nikNumber,
        'serial': 'PARADISE CONNECT',
        if (locationId != null) 'location_id': locationId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (note != null) 'note': note,
      });

      if (fileBytesData != null && fileBytesData.isNotEmpty) {
        for (var i = 0; i < fileBytesData.length; i++) {
          formData.files.add(MapEntry(
            'files[]',
            MultipartFile.fromBytes(fileBytesData[i], filename: 'photo_$i.jpg'),
          ));
        }
      } else {
        for (var path in filePaths) {
          formData.files.add(MapEntry(
            'files[]',
            await MultipartFile.fromFile(path),
          ));
        }
      }

      final response = await dio.post('/attendance/activity', data: formData);
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel && e.error == 'SESSION_EXPIRED') throw Exception('SESSION_EXPIRED');
      throw Exception(e.response?.data?['message'] ?? 'Gagal submit activity');
    }
  }
}
