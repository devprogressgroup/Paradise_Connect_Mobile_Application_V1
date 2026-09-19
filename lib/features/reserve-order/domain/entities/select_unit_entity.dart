import 'package:equatable/equatable.dart';

class SelectUnitEntity extends Equatable {
  final int dealId;
  final int contactId;
  final int townshipId;
  final int? companyId;
  final int? clusterId;
  final String? clusterName;
  final int? productId;
  final int? propertyId;
  final String? propertyName;
  final String? productDisplayName;
  final bool isWaitingList;
  final int? statusId;
  final String? statusName;

  /// Label status sudah disederhanakan oleh backend ("Available" / "Not Available") —
  /// `ReserveOrderController::selectUnit`, dipakai langsung tanpa perlu resolve `status_id` lagi.
  final String displayStatusName;
  final String? unitName;

  const SelectUnitEntity({
    required this.dealId,
    required this.contactId,
    required this.townshipId,
    this.companyId,
    this.clusterId,
    this.clusterName,
    this.productId,
    this.propertyId,
    this.propertyName,
    this.productDisplayName,
    this.isWaitingList = false,
    this.statusId,
    this.statusName,
    required this.displayStatusName,
    this.unitName,
  });

  bool get isAvailable => displayStatusName == 'Available';

  @override
  List<Object?> get props => [
    dealId,
    contactId,
    townshipId,
    companyId,
    clusterId,
    clusterName,
    productId,
    propertyId,
    propertyName,
    productDisplayName,
    isWaitingList,
    statusId,
    statusName,
    displayStatusName,
    unitName,
  ];
}
