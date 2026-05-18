import 'package:equatable/equatable.dart';

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
  final int? salesTeamId;
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
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? lostDate;
  final int? lostReasonId;
  final String? lostReasonNote;

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
    this.salesTeamId,
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
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.lostDate,
    this.lostReasonId,
    this.lostReasonNote
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
    int? salesTeamId,
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
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? lostDate,
    int? lostReasonId,
    String? lostReasonNote,
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
      salesTeamId: salesTeamId ?? this.salesTeamId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lostDate: lostDate ?? this.lostDate,
      lostReasonId: lostReasonId ?? this.lostReasonId,
      lostReasonNote: lostReasonNote ?? this.lostReasonNote,
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
    salesTeamId,
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
    createdAt,
    updatedAt,
    deletedAt,
    lostDate,
    lostReasonId,
    lostReasonNote
  ];
}

