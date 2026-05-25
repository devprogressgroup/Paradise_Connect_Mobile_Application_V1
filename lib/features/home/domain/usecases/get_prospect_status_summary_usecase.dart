import '../entities/prospect_status_summary_entity.dart';
import '../repositories/report_whatsapp_repository.dart';

class GetProspectStatusSummaryUseCase {
  final ReportRepository repository;
  GetProspectStatusSummaryUseCase(this.repository);

  Future<ProspectStatusSummaryEntity> call({String? startDate, String? endDate}) =>
      repository.getProspectStatusSummary(startDate: startDate, endDate: endDate);
}
