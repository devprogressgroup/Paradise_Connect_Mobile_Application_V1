import 'dart:typed_data';
import 'package:progress_group/features/attandance/data/datasource/attendance_remote_datasource.dart';
import 'package:progress_group/features/attandance/data/models/attendance_activity_model.dart';
import 'package:progress_group/features/attandance/data/models/attendance_model.dart';
import 'package:progress_group/features/attandance/data/models/attendance_approval_model.dart';
import 'package:progress_group/features/attandance/data/models/location_model.dart';
import 'package:progress_group/features/attandance/domain/entities/attendance_activity_entity.dart';
import 'package:progress_group/features/attandance/domain/entities/attandance_entity.dart';
import 'package:progress_group/features/attandance/domain/entities/attendance_approval_entity.dart';
import 'package:progress_group/features/attandance/domain/entities/location_entity.dart';

abstract class AttendanceRepository {
  Future<({List<AttendanceEntity> data, int lastPage})> getAttendance({List<int>? salesPersonIds, String? startDate, String? endDate, int page = 1});
  Future<AttendanceEntity?> getTodayAttendance();
  Future<List<AttendanceLocation>> getLocations();
  Future<List<AttendanceLocation>> getOfficeLocations();
  Future<void> submitAttendance({required String datetime,required int flag,required String location,String? note,String? filePath,Uint8List? fileBytes,required int nikNumber,int? locationId,String? latitude,String? longitude,});
  Future<void> submitAttendanceActivity({required String datetime,required int flag,required String location,String? note,required List<String> filePaths,List<Uint8List>? fileBytesData,required int nikNumber,int? locationId,String? latitude,String? longitude,});
  Future<({List<AttendanceActivityEntity> data, int lastPage})> getAttendanceActivity({List<int>? salesPersonIds, String? startDate, String? endDate, String? location, int page, int perPage});
  Future<void> validasiCheckIn({required int logId, required int statusValidasi, String? noteValidasi});
  Future<({List<AttendanceApprovalEntity> data, int lastPage})> getAttendanceApprovalToday({String? search, String? status, int? flag, int page = 1, int perPage = 10});
  Future<void> postAttendanceApproval({required int logId, required int approve});
}

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remote;

  AttendanceRepositoryImpl(this.remote);

  @override
  Future<List<AttendanceLocation>> getLocations() async {
    final result = await remote.getLocations();
    final list = result['data'] as List;
    return list.map((e) => AttendanceLocationModel.fromJson(e)).toList();
  }

  @override
  Future<List<AttendanceLocation>> getOfficeLocations() async {
    final result = await remote.getOfficeLocations();
    final list = result['data']['data'] as List;
    return list.map((e) => AttendanceLocationModel.fromJson(e)).toList();
  }

  @override
  Future<AttendanceEntity?> getTodayAttendance() async {
    final result = await remote.getTodayAttendance();
    if (result['status'] != true) return null;

    final data = result['data'];
    if (data == null) return null;

    final date = data['date'] as String;
    final logs = data['logs'] as List? ?? [];

    String? clockIn, clockOut, checkInActivity;
    String? location0, location1, location6;
    String? note0, note1, note6;
    List<String>? fileAttchment0, fileAttchment1, fileAttchment6;

    for (var log in logs) {
      final flag = log['flag'] as int;
      final datetime = log['datetime'] as String?;
      final locationName = log['location_name'] as String?;
      final note = log['note'] as String?;
      final files = (log['file_attachment'] as List?)?.map((e) => e.toString()).toList();

      if (flag == 0) {
        clockIn = datetime;
        location0 = locationName;
        note0 = note;
        fileAttchment0 = files;
      } else if (flag == 1) {
        clockOut = datetime;
        location1 = locationName;
        note1 = note;
        fileAttchment1 = files;
      } else if (flag == 6) {
        checkInActivity = datetime;
        location6 = locationName;
        note6 = note;
        fileAttchment6 = files;
      }
    }

    return AttendanceEntity(
      date: date,
      fullName: null,
      location: location0 ?? location1 ?? '',
      clockIn: clockIn,
      clockOut: clockOut,
      checkInActivity: checkInActivity,
      location0: location0,
      location1: location1,
      location6: location6,
      note0: note0,
      note1: note1,
      note6: note6,
      fileAttchment0: fileAttchment0,
      fileAttchment1: fileAttchment1,
      fileAttchment6: fileAttchment6,
    );
  }

  @override
  Future<({List<AttendanceEntity> data, int lastPage})> getAttendance({List<int>? salesPersonIds, String? startDate, String? endDate, int page = 1}) async {
    final result = await remote.getAttendance(salesPersonIds: salesPersonIds, startDate: startDate, endDate: endDate, page: page);

    final pagination = result['data'] as Map<String, dynamic>;
    final list = pagination['data'] as List;
    final lastPage = (pagination['last_page'] as num?)?.toInt() ?? 1;
    final models = list.map((e) => AttendanceModel.fromJson(e)).toList();

    // Grouping by Date and FullName to merge ClockIn and ClockOut
    final Map<String, AttendanceEntity> grouped = {};

    for (var m in models) {
      final key = "${m.date}_${m.fullName}";
      if (!grouped.containsKey(key)) {
        grouped[key] = m;
      } else {
        final existing = grouped[key]!;
        grouped[key] = AttendanceEntity(
          date: m.date,
          fullName: m.fullName,
          location: m.location.isNotEmpty ? m.location : existing.location,
          clockIn: m.clockIn ?? existing.clockIn,
          clockOut: m.clockOut ?? existing.clockOut,
          checkInActivity: m.checkInActivity ?? existing.checkInActivity,
          fileAttchment0: (m.fileAttchment0 != null && m.fileAttchment0!.isNotEmpty) ? m.fileAttchment0 : existing.fileAttchment0,
          fileAttchment1: (m.fileAttchment1 != null && m.fileAttchment1!.isNotEmpty) ? m.fileAttchment1 : existing.fileAttchment1,
          fileAttchment6: (m.fileAttchment6 != null && m.fileAttchment6!.isNotEmpty) ? m.fileAttchment6 : existing.fileAttchment6,
          note0: m.note0 ?? existing.note0,
          note1: m.note1 ?? existing.note1,
          note6: m.note6 ?? existing.note6,
          location0: m.location0 ?? existing.location0,
          location1: m.location1 ?? existing.location1,
          location6: m.location6 ?? existing.location6,
        );
      }
    }

    return (data: grouped.values.toList(), lastPage: lastPage);
  }

  @override
  Future<void> validasiCheckIn({required int logId, required int statusValidasi, String? noteValidasi}) async {
    await remote.postValidasiCheckIn(logId: logId, statusValidasi: statusValidasi, noteValidasi: noteValidasi);
  }

  @override
  Future<({List<AttendanceActivityEntity> data, int lastPage})> getAttendanceActivity({List<int>? salesPersonIds, String? startDate, String? endDate, String? location, int page = 1, int perPage = 20}) async {
    final result = await remote.getAttendanceActivity(
      salesPersonIds: salesPersonIds,
      startDate: startDate,
      endDate: endDate,
      location: location,
      page: page,
      perPage: perPage,
    );
    final pagination = result['data'] as Map<String, dynamic>;
    final list = pagination['data'] as List;
    final lastPage = (pagination['last_page'] as num?)?.toInt() ?? 1;
    final data = list.map((e) => AttendanceActivityModel.fromJson(e as Map<String, dynamic>)).toList();
    return (data: data, lastPage: lastPage);
  }

  @override
  Future<void> submitAttendance({   required String datetime,   required int flag,   required String location,   String? note,   String? filePath,   Uint8List? fileBytes,   required int nikNumber,   int? locationId,   String? latitude,   String? longitude, }) async {
    await remote.postAttendance(
      attendanceDatetime: datetime,
      flag: flag,
      locationName: location,
      note: note,
      filePath: filePath,
      fileBytes: fileBytes,
      nikNumber: nikNumber,
      locationId: locationId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<void> submitAttendanceActivity({  required String datetime,  required int flag,  required String location,  String? note,  required List<String> filePaths,  List<Uint8List>? fileBytesData,  required int nikNumber,  int? locationId,  String? latitude,  String? longitude,}) async {
    await remote.postAttendanceActivity(
      attendanceDatetime: datetime,
      flag: flag,
      locationName: location,
      note: note,
      filePaths: filePaths,
      fileBytesData: fileBytesData,
      nikNumber: nikNumber,
      locationId: locationId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<({List<AttendanceApprovalEntity> data, int lastPage})> getAttendanceApprovalToday({  String? search,  String? status,  int? flag,  int page = 1,  int perPage = 10,}) async {
    final result = await remote.getAttendanceApprovalToday(
      search: search,
      status: status,
      flag: flag,
      page: page,
      perPage: perPage,
    );
    if (result['status'] == true && result['data'] != null) {
      final rawData = result['data']['data'] as List<dynamic>? ?? [];
      final data = rawData.map((e) => AttendanceApprovalModel.fromJson(e as Map<String, dynamic>)).toList();
      final lastPage = (result['data']['last_page'] as num?)?.toInt() ?? 1;
      return (data: data, lastPage: lastPage);
    }
    return (data: <AttendanceApprovalEntity>[], lastPage: 1);
  }

  @override
  Future<void> postAttendanceApproval({required int logId, required int approve}) async {
    await remote.postAttendanceApproval(logId: logId, approve: approve);
  }
}