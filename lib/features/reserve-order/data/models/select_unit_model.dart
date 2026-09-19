import 'package:progress_group/features/reserve-order/domain/entities/select_unit_entity.dart';

class SelectUnitModel extends SelectUnitEntity {
  const SelectUnitModel({
    required super.dealId,
    required super.contactId,
    required super.townshipId,
    super.companyId,
    super.clusterId,
    super.clusterName,
    super.productId,
    super.propertyId,
    super.propertyName,
    super.productDisplayName,
    super.isWaitingList,
    super.statusId,
    super.statusName,
    required super.displayStatusName,
    super.unitName,
  });

  factory SelectUnitModel.fromJson(Map<String, dynamic> json) {
    return SelectUnitModel(
      dealId: json['deal_id'] as int,
      contactId: json['contact_id'] as int,
      townshipId: json['township_id'] as int,
      companyId: json['company_id'] as int?,
      clusterId: json['cluster_id'] as int?,
      clusterName: json['cluster_name'] as String?,
      productId: json['product_id'] as int?,
      propertyId: json['property_id'] as int?,
      propertyName: json['property_name'] as String?,
      productDisplayName: json['product_display_name'] as String?,
      isWaitingList:
          json['is_waiting_list'] == true || json['is_waiting_list'] == 1,
      statusId: json['status_id'] as int?,
      statusName: json['status_name'] as String?,
      displayStatusName:
          json['display_status_name'] as String? ?? 'Not Available',
      unitName: json['unit_name'] as String?,
    );
  }
}
