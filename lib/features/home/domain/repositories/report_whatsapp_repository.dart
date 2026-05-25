import '../entities/report_whatsapp_entity.dart';
import '../entities/prospect_status_summary_entity.dart';
import 'package:progress_group/features/home/data/models/report_whatsapp_model.dart';
import 'package:progress_group/features/home/data/models/prospect_status_summary_model.dart';

import '../../data/datasources/report_remote_datasource.dart';

abstract class ReportRepository {
  Future<ReportVolume> getVolumeReport({required String startDate, required String endDate, required String groupBy});
  Future<ProspectStatusSummaryEntity> getProspectStatusSummary({String? startDate, String? endDate});
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
    if (result['status'] == true) {
      return ReportVolumeModel.fromJson(result['data']);
    } else {
      throw Exception(result['message'] ?? "Error");
    }
  }

  @override
  Future<ProspectStatusSummaryEntity> getProspectStatusSummary({String? startDate, String? endDate}) async {
    final result = await remoteDataSource.getProspectStatusSummary(startDate: startDate, endDate: endDate);
    if (result['status'] == true) {
      return ProspectStatusSummaryModel.fromJson(result['data']);
    } else {
      throw Exception(result['message'] ?? "Error");
    }
  }
}
