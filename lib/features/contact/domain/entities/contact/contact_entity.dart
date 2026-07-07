import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';

class ContactEntity extends Equatable {
  final int? contactId;
  final String? hubspotContactId;
  final bool? isSyncHubspot;
  final String? salutation;
  final String? fullName;
  final String? primaryPhone;
  final String? whatsappNumber;
  final String? primaryEmail;
  final String? noKtp;
  final String? ktpAddress;
  final String? firstProject;
  final String? lastProject;
  final String? firstProduct;
  final String? lastProduct;
  final int? salesChannelId;
  final String? sumberInformasi1;
  final String? sumberInformasi2;
  final String? sumberInformasi2Name;
  final String? firstProjectCategory;
  final String? lastProjectCategory;
  final String? firstBlokNo;
  final String? lastBlokNo;
  final int? salesExecutiveId;
  final int? salesSupervisorId;
  final int? salesManagerId;
  final int? salesGeneralManagerId;
  final int? salesTeamId;
  final String? salesTeamName;
  final int? statusProspectId;
  final String? volumePlan;
  final int? visitCount;
  final String? generalNotes;
  final String? firstApptDate;
  final String? lastApptDate;
  final String? firstVisitDate;
  final String? lastVisitDate;
  final String? firstReserveDate;
  final String? lastReserveDate;
  final String? firstSpDate;
  final String? lastSpDate;
  final String? firstAkadDate;
  final String? lastAkadDate;
  final String? firstLostDate;
  final String? lastLostDate;
  final dynamic propertiesJson;
  final int? ownerId;
  final int? dealId;
  final List<dynamic>? propertyGroupsJson;
  final String? dealValue;
  final String? apptDate;
  final String? visitDate;
  final String? dealNote;
  final String? projectName;
  final String? blokNo;
  final String? ownerName;
  final String? salesExecutiveName;
  final String? salesSupervisorName;
  final String? salesManagerName;
  final String? salesGeneralManagerName;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? lostDate;
  final int? lostReasonId;
  final String? lostReasonNote;
  final int? firstProjectId;
  final int? lastProjectId;
  final int? firstClusterId;
  final int? lastClusterId;
  final int? firstCommercialId;
  final int? lastCommercialId;
  final int? firstProductId;
  final int? lastProductId;
  final String? productType;
  final String? nameSP;
  
  final bool? canEdit;
  final bool? canDelete;
  
  final List<SelectedUnit>? units;

  const ContactEntity({
    this.contactId,
    this.hubspotContactId,
    this.isSyncHubspot,
    this.salutation,
    this.fullName,
    this.primaryPhone,
    this.whatsappNumber,
    this.primaryEmail,
    this.noKtp,
    this.ktpAddress,
    this.firstProject,
    this.lastProject,
    this.firstProduct,
    this.lastProduct,
    this.salesChannelId,
    this.sumberInformasi1,
    this.sumberInformasi2,
    this.sumberInformasi2Name,
    this.firstProjectCategory,
    this.lastProjectCategory,
    this.firstBlokNo,
    this.lastBlokNo,
    this.salesExecutiveId,
    this.salesSupervisorId,
    this.salesManagerId,
    this.salesGeneralManagerId,
    this.salesTeamId,
    this.salesTeamName,
    this.statusProspectId,
    this.volumePlan,
    this.visitCount,
    this.generalNotes,
    this.firstApptDate,
    this.lastApptDate,
    this.firstVisitDate,
    this.lastVisitDate,
    this.firstReserveDate,
    this.lastReserveDate,
    this.firstSpDate,
    this.lastSpDate,
    this.firstAkadDate,
    this.lastAkadDate,
    this.firstLostDate,
    this.lastLostDate,
    this.propertiesJson,
    this.ownerId,
    this.dealId,
    this.propertyGroupsJson,
    this.dealValue,
    this.apptDate,
    this.visitDate,
    this.dealNote,
    this.projectName,
    this.blokNo,
    this.ownerName,
    this.salesExecutiveName,
    this.salesSupervisorName,
    this.salesManagerName,
    this.salesGeneralManagerName,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.lostDate,
    this.lostReasonId,
    this.lostReasonNote,
    this.firstProjectId,
    this.lastProjectId,
    this.firstClusterId,
    this.lastClusterId,
    this.firstCommercialId,
    this.lastCommercialId,
    this.firstProductId,
    this.lastProductId,
    this.productType,
    this.nameSP,
    this.canEdit,
    this.canDelete,
    this.units,
  });

  ContactEntity copyWith({
    int? contactId,
    String? hubspotContactId,
    bool? isSyncHubspot,
    String? salutation,
    String? fullName,
    String? primaryPhone,
    String? whatsappNumber,
    String? primaryEmail,
    String? noKtp,
    String? ktpAddress,
    String? firstProject,
    String? lastProject,
    String? firstProduct,
    String? lastProduct,
    int? salesChannelId,
    String? sumberInformasi1,
    String? sumberInformasi2,
    String? firstProjectCategory,
    String? lastProjectCategory,
    String? firstBlokNo,
    String? lastBlokNo,
    int? salesExecutiveId,
    int? salesSupervisorId,
    int? salesManagerId,
    int? salesGeneralManagerId,
    int? salesTeamId,
    String? salesTeamName,
    int? statusProspectId,
    String? volumePlan,
    int? visitCount,
    String? generalNotes,
    String? firstApptDate,
    String? lastApptDate,
    String? firstVisitDate,
    String? lastVisitDate,
    String? firstReserveDate,
    String? lastReserveDate,
    String? firstSpDate,
    String? lastSpDate,
    String? firstAkadDate,
    String? lastAkadDate,
    String? firstLostDate,
    String? lastLostDate,
    dynamic propertiesJson,
    int? ownerId,
    int? dealId,
    List<dynamic>? propertyGroupsJson,
    String? dealValue,
    String? apptDate,
    String? visitDate,
    String? dealNote,
    String? projectName,
    String? blokNo,
    String? ownerName,
    String? salesExecutiveName,
    String? salesSupervisorName,
    String? salesManagerName,
    String? salesGeneralManagerName,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? lostDate,
    int? lostReasonId,
    String? lostReasonNote,
    int? firstProjectId,
    int? lastProjectId,
    int? firstClusterId,
    int? lastClusterId,
    int? firstCommercialId,
    int? lastCommercialId,
    int? firstProductId,
    int? lastProductId,
    String? productType,
    String? nameSP,
    bool? canEdit,
    bool? canDelete,
    List<SelectedUnit>? units,
  }) {
    return ContactEntity(
      contactId: contactId ?? this.contactId,
      hubspotContactId: hubspotContactId ?? this.hubspotContactId,
      isSyncHubspot: isSyncHubspot ?? this.isSyncHubspot,
      salutation: salutation ?? this.salutation,
      fullName: fullName ?? this.fullName,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      primaryEmail: primaryEmail ?? this.primaryEmail,
      noKtp: noKtp ?? this.noKtp,
      ktpAddress: ktpAddress ?? this.ktpAddress,
      firstProject: firstProject ?? this.firstProject,
      lastProject: lastProject ?? this.lastProject,
      firstProduct: firstProduct ?? this.firstProduct,
      lastProduct: lastProduct ?? this.lastProduct,
      salesChannelId: salesChannelId ?? this.salesChannelId,
      sumberInformasi1: sumberInformasi1 ?? this.sumberInformasi1,
      sumberInformasi2: sumberInformasi2 ?? this.sumberInformasi2,
      sumberInformasi2Name: sumberInformasi2Name ?? this.sumberInformasi2Name,
      firstProjectCategory: firstProjectCategory ?? this.firstProjectCategory,
      lastProjectCategory: lastProjectCategory ?? this.lastProjectCategory,
      firstBlokNo: firstBlokNo ?? this.firstBlokNo,
      lastBlokNo: lastBlokNo ?? this.lastBlokNo,
      salesExecutiveId: salesExecutiveId ?? this.salesExecutiveId,
      salesSupervisorId: salesSupervisorId ?? this.salesSupervisorId,
      salesManagerId: salesManagerId ?? this.salesManagerId,
      salesGeneralManagerId: salesGeneralManagerId ?? this.salesGeneralManagerId,
      salesTeamId: salesTeamId ?? this.salesTeamId,
      salesTeamName: salesTeamName ?? this.salesTeamName,
      statusProspectId: statusProspectId ?? this.statusProspectId,
      volumePlan: volumePlan ?? this.volumePlan,
      visitCount: visitCount ?? this.visitCount,
      generalNotes: generalNotes ?? this.generalNotes,
      firstApptDate: firstApptDate ?? this.firstApptDate,
      lastApptDate: lastApptDate ?? this.lastApptDate,
      firstVisitDate: firstVisitDate ?? this.firstVisitDate,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      firstReserveDate: firstReserveDate ?? this.firstReserveDate,
      lastReserveDate: lastReserveDate ?? this.lastReserveDate,
      firstSpDate: firstSpDate ?? this.firstSpDate,
      lastSpDate: lastSpDate ?? this.lastSpDate,
      firstAkadDate: firstAkadDate ?? this.firstAkadDate,
      lastAkadDate: lastAkadDate ?? this.lastAkadDate,
      firstLostDate: firstLostDate ?? this.firstLostDate,
      lastLostDate: lastLostDate ?? this.lastLostDate,
      propertiesJson: propertiesJson ?? this.propertiesJson,
      ownerId: ownerId ?? this.ownerId,
      dealId: dealId ?? this.dealId,
      propertyGroupsJson: propertyGroupsJson ?? this.propertyGroupsJson,
      dealValue: dealValue ?? this.dealValue,
      apptDate: apptDate ?? this.apptDate,
      visitDate: visitDate ?? this.visitDate,
      dealNote: dealNote ?? this.dealNote,
      projectName: projectName ?? this.projectName,
      blokNo: blokNo ?? this.blokNo,
      ownerName: ownerName ?? this.ownerName,
      salesExecutiveName: salesExecutiveName ?? this.salesExecutiveName,
      salesSupervisorName: salesSupervisorName ?? this.salesSupervisorName,
      salesManagerName: salesManagerName ?? this.salesManagerName,
      salesGeneralManagerName: salesGeneralManagerName ?? this.salesGeneralManagerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lostDate: lostDate ?? this.lostDate,
      lostReasonId: lostReasonId ?? this.lostReasonId,
      lostReasonNote: lostReasonNote ?? this.lostReasonNote,
      firstProjectId: firstProjectId ?? this.firstProjectId,
      lastProjectId: lastProjectId ?? this.lastProjectId,
      firstClusterId: firstClusterId ?? this.firstClusterId,
      lastClusterId: lastClusterId ?? this.lastClusterId,
      firstCommercialId: firstCommercialId ?? this.firstCommercialId,
      lastCommercialId: lastCommercialId ?? this.lastCommercialId,
      firstProductId: firstProductId ?? this.firstProductId,
      lastProductId: lastProductId ?? this.lastProductId,
      productType: productType ?? this.productType,
      nameSP: nameSP ?? this.nameSP,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      units: units ?? this.units,
    );
  }


  @override
  List<Object?> get props => [
    contactId,
    hubspotContactId,
    isSyncHubspot,
    salutation,
    fullName,
    primaryPhone,
    whatsappNumber,
    primaryEmail,
    noKtp,
    ktpAddress,
    firstProject,
    lastProject,
    firstProduct,
    lastProduct,
    salesChannelId,
    sumberInformasi1,
    sumberInformasi2,
    sumberInformasi2Name,
    firstProjectCategory,
    lastProjectCategory,
    firstBlokNo,
    lastBlokNo,
    salesExecutiveId,
    salesSupervisorId,
    salesManagerId,
    salesGeneralManagerId,
    salesTeamId,
    salesTeamName,
    statusProspectId,
    volumePlan,
    visitCount,
    generalNotes,
    firstApptDate,
    lastApptDate,
    firstVisitDate,
    lastVisitDate,
    firstReserveDate,
    lastReserveDate,
    firstSpDate,
    lastSpDate,
    firstAkadDate,
    lastAkadDate,
    firstLostDate,
    lastLostDate,
    propertiesJson,
    ownerId,
    dealId,
    propertyGroupsJson,
    dealValue,
    apptDate,
    visitDate,
    dealNote,
    projectName,
    blokNo,
    ownerName,
    salesExecutiveName,
    salesSupervisorName,
    salesManagerName,
    salesGeneralManagerName,
    createdAt,
    updatedAt,
    deletedAt,
    lostDate,
    lostReasonId,
    lostReasonNote,
    firstProjectId,
    lastProjectId,
    firstClusterId,
    lastClusterId,
    firstCommercialId,
    lastCommercialId,
    firstProductId,
    lastProductId,
    productType,
    nameSP,
    canEdit,
    canDelete,
    units,
  ];
}

