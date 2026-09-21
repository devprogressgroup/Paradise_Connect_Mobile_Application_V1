import 'package:dartz/dartz.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_list_item_entity.dart';
import 'package:progress_group/features/reserve-order/domain/repositories/reserve_order_repository.dart';

class GetReserveOrderListUseCase {
  final ReserveOrderRepository repository;

  GetReserveOrderListUseCase(this.repository);

  Future<Either<String, ReserveOrderListResultEntity>> call({
    String? search,
    List<int>? statusReserveIds,
    bool? rejected,
    String? sort,
    List<int>? salesChannelIds,
    List<int>? channelDetailIds,
    List<int>? ownerIds,
    List<int>? salesExecutiveIds,
    List<int>? salesSupervisorIds,
    List<int>? salesManagerIds,
    List<int>? generalManagerIds,
    int page = 1,
    int perPage = 15,
  }) async {
    return await repository.getReserveOrderList(
      search: search,
      statusReserveIds: statusReserveIds,
      rejected: rejected,
      sort: sort,
      salesChannelIds: salesChannelIds,
      channelDetailIds: channelDetailIds,
      ownerIds: ownerIds,
      salesExecutiveIds: salesExecutiveIds,
      salesSupervisorIds: salesSupervisorIds,
      salesManagerIds: salesManagerIds,
      generalManagerIds: generalManagerIds,
      page: page,
      perPage: perPage,
    );
  }
}
