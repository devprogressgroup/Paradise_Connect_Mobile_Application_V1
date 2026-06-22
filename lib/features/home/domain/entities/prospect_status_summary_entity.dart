class ProspectStatusItemEntity {
  final int prospectStatusId;
  final String statusValue;
  final String statusName;
  final String? startDate;
  final String? endDate;
  final int totalContacts;
  final int totalDeals;

  const ProspectStatusItemEntity({
    required this.prospectStatusId,
    required this.statusValue,
    required this.statusName,
    required this.totalContacts,
    required this.totalDeals,
     this.startDate,
     this.endDate,
  });
}

class ProspectStatusSummaryEntity {
  final int totalContacts;
  final int totalDeals;
  final List<ProspectStatusItemEntity> statuses;

  const ProspectStatusSummaryEntity({
    required this.totalContacts,
    required this.totalDeals,
    required this.statuses,
  });
}
