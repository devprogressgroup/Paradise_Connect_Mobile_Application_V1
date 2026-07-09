import '../entities/sales_channel_summary_entity.dart';
import '../repositories/report_whatsapp_repository.dart';

class GetSalesChannelsSummaryUseCase {
  final ReportRepository repository;
  GetSalesChannelsSummaryUseCase(this.repository);

  Future<SalesChannelSummaryEntity> call({String? startDate, String? endDate}) =>
      repository.getSalesChannelsSummary(startDate: startDate, endDate: endDate);
}
