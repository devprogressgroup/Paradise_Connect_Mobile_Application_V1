import '../../domain/entities/prospect_status_summary_entity.dart';

class ProspectStatusItemModel extends ProspectStatusItemEntity {
  const ProspectStatusItemModel({
    required super.prospectStatusId,
    required super.statusValue,
    required super.statusName,
    required super.totalContacts,
    required super.totalDeals,
  });

  factory ProspectStatusItemModel.fromJson(Map<String, dynamic> json) {
    return ProspectStatusItemModel(
      prospectStatusId: json['prospect_status_id'] as int,
      statusValue: json['status_value'] as String,
      statusName: json['status_name'] as String,
      totalContacts: json['total_contacts'] as int,
      totalDeals: json['total_deals'] as int,
    );
  }
}

class ProspectStatusSummaryModel extends ProspectStatusSummaryEntity {
  const ProspectStatusSummaryModel({
    required super.totalContacts,
    required super.totalDeals,
    required super.statuses,
  });

  factory ProspectStatusSummaryModel.fromJson(Map<String, dynamic> json) {
    final statusList = (json['statuses'] as List<dynamic>)
        .map((e) => ProspectStatusItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProspectStatusSummaryModel(
      totalContacts: json['total_contacts'] as int,
      totalDeals: json['total_deals'] as int,
      statuses: statusList,
    );
  }
}
