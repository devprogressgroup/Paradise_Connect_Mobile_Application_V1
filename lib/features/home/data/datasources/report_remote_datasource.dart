import 'package:dio/dio.dart';

abstract class ReportRemoteDataSource {
  Future<Map<String, dynamic>> getVolumeReport(String start, String end, String group);
  Future<Map<String, dynamic>> getProspectStatusSummary({String? startDate, String? endDate});
  Future<Map<String, dynamic>> getSalesChannelsSummary({String? startDate, String? endDate});
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final Dio dio;
  ReportRemoteDataSourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> getVolumeReport(String start, String end, String group) async {
    final response = await dio.get(
      '/whatsapp/report/volume',
      queryParameters: {
        'start_date': start,
        'end_date': end,
        'group_by': group,
      },
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getProspectStatusSummary({String? startDate, String? endDate}) async {
    final Map<String, dynamic> params = {};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    final response = await dio.get(
      '/sales/prospect-statuses',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getSalesChannelsSummary({String? startDate, String? endDate}) async {
    final Map<String, dynamic> params = {};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    final response = await dio.get(
      '/sales/channels-summary',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }
}