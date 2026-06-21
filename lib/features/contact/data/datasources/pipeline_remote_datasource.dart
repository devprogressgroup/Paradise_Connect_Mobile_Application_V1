import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/models/pipeline/pipeline_deal_model.dart';

/// Datasource Sales Pipeline (Model A) — hit GET /deals (envelope {status,message,data:{...paginate}}).
abstract class PipelineRemoteDataSource {
  Future<PipelineDealsPage> getDeals({
    List<int>? statusIds,
    String? search,
    int page,
    int perPage,
  });
}

class PipelineRemoteDataSourceImpl implements PipelineRemoteDataSource {
  final Dio dio;
  PipelineRemoteDataSourceImpl(this.dio);

  static int _toInt(dynamic v) => v is int ? v : (int.tryParse('${v ?? ''}') ?? 0);

  @override
  Future<PipelineDealsPage> getDeals({
    List<int>? statusIds,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await dio.get('/deals', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (statusIds != null && statusIds.isNotEmpty)
          'status_prospect_id': statusIds.join(','),
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final d = Map<String, dynamic>.from(body['data'] as Map);
        final list = (d['data'] as List? ?? [])
            .map((e) => PipelineDeal.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return PipelineDealsPage(
          items: list,
          currentPage: _toInt(d['current_page'] ?? 1),
          lastPage: _toInt(d['last_page'] ?? 1),
          total: _toInt(d['total'] ?? list.length),
        );
      }
      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat pipeline') : 'Gagal memuat pipeline');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat pipeline'));
    }
  }
}
