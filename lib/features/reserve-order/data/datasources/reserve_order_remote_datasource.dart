import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_status_model.dart';

abstract class ReserveOrderRemoteDataSource {
  Future<List<ReserveStatusModel>> getReserveStatuses();
}

class ReserveOrderRemoteDataSourceImpl implements ReserveOrderRemoteDataSource {
  final Dio dio;

  ReserveOrderRemoteDataSourceImpl(this.dio);

  @override
  Future<List<ReserveStatusModel>> getReserveStatuses() async {
    try {
      final response = await dio.get('/reserve-order/status');

      if (response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ReserveStatusModel.fromJson(json)).toList();
      }

      throw Exception(response.data['message'] ?? 'Failed to load reserve statuses');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Failed to load reserve statuses'));
    }
  }
}
