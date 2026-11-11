import 'package:progress_group/features/contact/domain/entities/dropdown_option.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_filter_sales_entity.dart';

class ReserveOrderFilterSalesModel extends ReserveOrderFilterSalesEntity {
  const ReserveOrderFilterSalesModel({
    required super.owner,
    required super.salesExecutive,
    required super.salesSupervisor,
    required super.salesManager,
    required super.generalManager,
    required super.salesTeam,
  });

  /// [json] = field `data` dari response `GET /reserve-order/filter-sales`.
  factory ReserveOrderFilterSalesModel.fromJson(Map<String, dynamic> json) {
    List<DropdownOption> parse(String key) {
      final list = json[key];
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => DropdownOption(
                id: (e['id'] as num).toInt(),
                name: (e['name'] ?? '').toString(),
              ))
          .toList();
    }

    return ReserveOrderFilterSalesModel(
      owner: parse('owner'),
      salesExecutive: parse('sales_executive'),
      salesSupervisor: parse('sales_supervisor'),
      salesManager: parse('sales_manager'),
      generalManager: parse('general_manager'),
      salesTeam: parse('sales_team'),
    );
  }
}
