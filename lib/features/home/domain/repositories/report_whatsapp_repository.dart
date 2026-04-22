import '../entities/report_whatsapp_entity.dart';
import 'package:progress_group/features/home/data/models/report_whatsapp_model.dart';

import '../../data/datasources/report_remote_datasource.dart';

abstract class ReportRepository {
  Future<ReportVolume> getVolumeReport({required String startDate,required String endDate,required String groupBy});
}
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;
  ReportRepositoryImpl(this.remoteDataSource);

  @override
  Future<ReportVolume> getVolumeReport({
    required String startDate,
    required String endDate,
    required String groupBy,
  }) async {
    final result = await remoteDataSource.getVolumeReport(startDate, endDate, groupBy);
    
    // Menggunakan BaseResponse seperti pola kamu sebelumnya
    if (result['status'] == true) {
      return ReportVolumeModel.fromJson(result['data']);
    } else {
      throw Exception(result['message'] ?? "Error");
    }
  }
}
