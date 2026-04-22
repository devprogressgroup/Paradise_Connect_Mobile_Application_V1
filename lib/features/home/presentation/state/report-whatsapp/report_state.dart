import '../../../domain/entities/report_whatsapp_entity.dart';

abstract class ReportState {}

class ReportInitial extends ReportState {}
class ReportLoading extends ReportState {}
class ReportLoaded extends ReportState {
  final ReportVolume report;
  ReportLoaded(this.report);
}

class ReportError extends ReportState {
  final String message;
  ReportError(this.message);
}