import 'package:progress_group/features/home/domain/repositories/report_whatsapp_repository.dart';

import '../entities/report_whatsapp_entity.dart';

class GetVolumeReportUseCase {
  final ReportRepository repository;
  GetVolumeReportUseCase(this.repository);

  Future<ReportVolume> call(String start, String end, String group) {
    return repository.getVolumeReport(startDate: start, endDate: end, groupBy: group);
  }
}