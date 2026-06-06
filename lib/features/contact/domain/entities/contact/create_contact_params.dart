import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class CreateContactParams extends Equatable {
  final String? fullName;
  final String? salutation;
  final String? primaryPhone;
  final String? primaryEmail;
  final String? whatsappNumber;
  final String? noKtp;
  final String? ktpAddress;
  final String? firstProject;
  final String? lastProject;
  final String? firstProduct;
  final String? lastProduct;
  final String? firstProjectCategory;
  final String? lastProjectCategory;
  final String? firstBlokNo;
  final String? lastBlokNo;
  final int? ownerId;
  final int? salesExecutiveId;
  final int? salesManagerId;
  final int? salesSupervisorId;
  final int? salesGeneralManagerId;
  final int? salesTeamId;
  final int? salesChannelId;
  final int? statusProspectId;
  final String? sumberInformasi1;
  final String? sumberInformasi2;
  final String? volumePlan;
  final int? visitCount;
  final String? generalNotes;
  final String? firstApptDate;
  final String? lastApptDate;
  final String? firstVisitDate;
  final String? lastVisitDate;
  final String? firstSPDate;
  final String? lastSPDate;
  final String? reserveDate;
  final String? firstReserveDate;
  final String? lastReserveDate;
  final String? dealValue;
  final String? lostReasonNote;
  final Map<String, dynamic>? properties;
  final List<Map<String, dynamic>>? propertiesJson;
  final int? lostReasonId;
  final String? firstLostDate;
  final String? lastLostDate;
  final String? lostDate;
  final String? nameSP;
  final String? firstAkadDate;
  final String? lastAkadDate;
  final int? firstProjectId;
  final int? lastProjectId;
  final int? firstClusterId;
  final int? lastClusterId;
  final int? firstCommercialId;
  final int? lastCommercialId;
  final int? firstProductId;
  final int? lastProductId;
  final Map<int, Uint8List>? propertyFileBytes;
  final Map<int, String>? propertyFileNames;
  final String? periodePameranDate;
  final String? productType;

  const CreateContactParams({
    this.fullName,
    this.salutation,
    this.primaryPhone,
    this.primaryEmail,
    this.whatsappNumber,
    this.noKtp,
    this.ktpAddress,
    this.firstProject,
    this.lastProject,
    this.firstProduct,
    this.lastProduct,
    this.firstProjectCategory,
    this.lastProjectCategory,
    this.firstBlokNo,
    this.lastBlokNo,
    this.ownerId,
    this.salesExecutiveId,
    this.salesManagerId,
    this.salesSupervisorId,
    this.salesGeneralManagerId,
    this.salesTeamId,
    this.salesChannelId,
    this.statusProspectId,
    this.sumberInformasi1,
    this.sumberInformasi2,
    this.volumePlan,
    this.visitCount,
    this.generalNotes,
    this.firstApptDate,
    this.lastApptDate,
    this.firstVisitDate,
    this.lastVisitDate,
    this.firstSPDate,
    this.lastSPDate,
    this.reserveDate,
    this.firstReserveDate,
    this.lastReserveDate,
    this.dealValue,
    this.lostReasonNote,
    this.properties,
    this.propertiesJson,
    this.lostReasonId,
    this.firstLostDate,
    this.lastLostDate,
    this.lostDate,
    this.nameSP,
    this.firstAkadDate,
    this.lastAkadDate,
    this.firstProjectId,
    this.lastProjectId,
    this.firstClusterId,
    this.lastClusterId,
    this.firstCommercialId,
    this.lastCommercialId,
    this.firstProductId,
    this.lastProductId,
    this.propertyFileBytes,
    this.propertyFileNames,
    this.periodePameranDate,
    this.productType,
  });

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'full_name': fullName,
      if (salutation != null) 'salutation': salutation,
      if (primaryPhone != null) 'primary_phone': primaryPhone,
      if (primaryEmail != null) 'primary_email': primaryEmail,
      if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
      if (noKtp != null) 'no_ktp': noKtp,
      if (ktpAddress != null) 'ktp_address': ktpAddress,
      if (firstProject != null) 'first_project': firstProject,
      if (lastProject != null) 'last_project': lastProject,
      if (firstProduct != null) 'first_product': firstProduct,
      'last_product': lastProduct,
      if (firstProjectCategory != null) 'first_project_category': firstProjectCategory,
      'last_project_category': lastProjectCategory,
      if (firstBlokNo != null) 'first_blok_no': firstBlokNo,
      if (lastBlokNo != null) 'last_blok_no': lastBlokNo,
      if (ownerId != null) 'owner_id': ownerId,
      if (salesExecutiveId != null) 'sales_executive_id': salesExecutiveId,
      if (salesManagerId != null) 'sales_manager_id': salesManagerId,
      if (salesSupervisorId != null) 'sales_supervisor_id': salesSupervisorId,
      if (salesGeneralManagerId != null) 'sales_general_manager_id': salesGeneralManagerId,
      if (salesTeamId != null) 'sales_team_id': salesTeamId,
      if (salesChannelId != null) 'sales_channel_id': salesChannelId,
      if (statusProspectId != null) 'status_prospect_id': statusProspectId,
      if (sumberInformasi1 != null) 'sumber_informasi1': sumberInformasi1,
      if (sumberInformasi2 != null) 'sumber_informasi2': sumberInformasi2,
      if (volumePlan != null) 'volume_plan': volumePlan,
      if (visitCount != null) 'visit_count': visitCount,
      if (generalNotes != null) 'general_notes': generalNotes,
      if (firstApptDate != null) 'first_appt_date': firstApptDate,
      if (lastApptDate != null) 'last_appt_date': lastApptDate,
      if (firstVisitDate != null) 'first_visit_date': firstVisitDate,
      if (lastVisitDate != null) 'last_visit_date': lastVisitDate,
      if (dealValue != null) 'deal_value': dealValue,
      if (lostReasonNote != null) 'lost_reason_note': lostReasonNote,
      if (firstSPDate != null) 'first_sp_date': firstSPDate,
      if (lastSPDate != null) 'last_sp_date': lastSPDate,
      if (reserveDate != null) 'reserve_date': reserveDate,
      if (firstReserveDate != null) 'first_reserve_date': firstReserveDate,
      if (lastReserveDate != null) 'last_reserve_date': lastReserveDate,
      if (properties != null) 'properties': properties,
      if (propertiesJson != null) 'properties_json': propertiesJson,
      if (lostReasonId != null) 'lost_reason_id': lostReasonId,
      if (firstLostDate != null) 'first_lost_date': firstLostDate,
      if (lastLostDate != null) 'last_lost_date': lastLostDate,
      if (lostDate != null) 'lost_date': lostDate,
      if (nameSP != null) 'name_sp': nameSP,
      if (firstAkadDate != null) 'first_akad_date': firstAkadDate,
      if (lastAkadDate != null) 'last_akad_date': lastAkadDate,
      if (firstProjectId != null) 'first_project_id': firstProjectId,
      if (lastProjectId != null) 'last_project_id': lastProjectId,
      if (firstClusterId != null) 'first_cluster_id': firstClusterId,
      if (lastClusterId != null) 'last_cluster_id': lastClusterId,
      if (firstCommercialId != null) 'first_commercial_id': firstCommercialId,
      if (lastCommercialId != null) 'last_commercial_id': lastCommercialId,
      if (firstProductId != null) 'first_product_id': firstProductId,
      if (lastProductId != null) 'last_product_id': lastProductId,
      if (periodePameranDate != null) 'periode_pameran_date': periodePameranDate,
      'product_type': productType,
    };
  }

  @override
  List<Object?> get props => [
    fullName,
    salutation,
    primaryPhone,
    primaryEmail,
    whatsappNumber,
    noKtp,
    ktpAddress,
    firstProject,
    lastProject,
    firstProduct,
    lastProduct,
    firstProjectCategory,
    lastProjectCategory,
    firstBlokNo,
    lastBlokNo,
    ownerId,
    salesExecutiveId,
    salesManagerId,
    salesSupervisorId,
    salesGeneralManagerId,
    salesTeamId,
    salesChannelId,
    statusProspectId,
    sumberInformasi1,
    sumberInformasi2,
    volumePlan,
    visitCount,
    generalNotes,
    firstApptDate,
    lastApptDate,
    firstVisitDate,
    lastVisitDate,
    dealValue,
    lostReasonNote,
    firstSPDate,
    lastSPDate,
    properties,
    propertiesJson,
    lostReasonId,
    firstLostDate,
    lastLostDate,
    lostDate,
    nameSP,
    firstReserveDate,
    lastReserveDate,
    lostReasonId,
    firstAkadDate,
    lastAkadDate,
    firstProjectId,
    lastProjectId,
    firstClusterId,
    lastClusterId,
    firstCommercialId,
    lastCommercialId,
    firstProductId,
    lastProductId,
    propertyFileBytes,
    propertyFileNames,
    periodePameranDate,
    productType,
  ];
}
