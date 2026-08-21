import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';

enum ContactStatus {
  initial,
  loading,
  loaded,
  error,
  creating,
  createSuccess,
  updateSuccess,
  loadingDetail,
  detailLoaded,
  deleting,
  deleteSuccess,
}

class ContactState extends Equatable {
  final ContactStatus status;
  final List<ContactEntity> contacts;
  final String? errorMessage;
  final int currentPage;
  final bool hasReachedMax;
  final String? search;
  final String? startDate;
  final String? endDate;
  final List<int>? ownerIds;
  final List<int>? statusProspectIds;
  final List<int>? salesChannelIds;
  final List<int>? salesTeamIds;
  final List<int>? salesExecutiveIds;
  final List<int>? salesSupervisorIds;
  final List<int>? salesManagerIds;
  final List<int>? salesGeneralManagerIds;
  final ContactEntity? contactDetail;
  final String? apptStartDate;
  final String? apptEndDate;
  final String? visitStartDate;
  final String? visitEndDate;
  final String? reserveStartDate;
  final String? reserveEndDate;
  final String? spStartDate;
  final String? spEndDate;
  final String? lostStartDate;
  final String? lostEndDate;
  final String? lastProject;
  final int? totalContacts;
  final List<ContactEntity> duplicateCheckContacts;
  final String? sort;

  const ContactState({
    this.status = ContactStatus.initial,
    this.contacts = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.search,
    this.startDate,
    this.endDate,
    this.ownerIds,
    this.statusProspectIds,
    this.salesChannelIds,
    this.salesTeamIds,
    this.salesExecutiveIds,
    this.salesSupervisorIds,
    this.salesManagerIds,
    this.salesGeneralManagerIds,
    this.contactDetail,
    this.apptStartDate,
    this.apptEndDate,
    this.visitStartDate,
    this.visitEndDate,
    this.reserveStartDate,
    this.reserveEndDate,
    this.spStartDate,
    this.spEndDate,
    this.lostStartDate,
    this.lostEndDate,
    this.lastProject,
    this.totalContacts,
    this.duplicateCheckContacts = const [],
    this.sort,
  });

  ContactState copyWith({
    ContactStatus? status,
    List<ContactEntity>? contacts,
    String? errorMessage,
    int? currentPage,
    bool? hasReachedMax,
    String? search,
    String? startDate,
    String? endDate,
    List<int>? ownerIds,
    List<int>? statusProspectIds,
    List<int>? salesChannelIds,
    List<int>? salesTeamIds,
    List<int>? salesExecutiveIds,
    List<int>? salesSupervisorIds,
    List<int>? salesManagerIds,
    List<int>? salesGeneralManagerIds,
    bool clearSearch = false,
    bool clearDates = false,
    bool clearOwner = false,
    bool clearStatus = false,
    bool clearSalesChannel = false,
    bool clearSalesTeam = false,
    bool clearSalesExecutive = false,
    bool clearSalesSupervisor = false,
    bool clearSalesManager = false,
    bool clearSalesGeneralManager = false,
    ContactEntity? contactDetail,
    String? apptStartDate,
    String? apptEndDate,
    String? visitStartDate,
    String? visitEndDate,
    String? reserveStartDate,
    String? reserveEndDate,
    String? spStartDate,
    String? spEndDate,
    String? lostStartDate,
    String? lostEndDate,
    String? lastProject,
    bool clearApptDates = false,
    bool clearVisitDates = false,
    bool clearReserveDates = false,
    bool clearSpDates = false,
    bool clearLostDates = false,
    bool clearProject = false,
    int? totalContacts,
    List<ContactEntity>? duplicateCheckContacts,
    String? sort,
    bool clearSort = false,
  }) {
    return ContactState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      search: clearSearch ? null : (search ?? this.search),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      ownerIds: clearOwner ? null : (ownerIds ?? this.ownerIds),
      statusProspectIds: clearStatus ? null : (statusProspectIds ?? this.statusProspectIds),
      salesChannelIds: clearSalesChannel ? null : (salesChannelIds ?? this.salesChannelIds),
      salesTeamIds: clearSalesTeam ? null : (salesTeamIds ?? this.salesTeamIds),
      salesExecutiveIds: clearSalesExecutive ? null : (salesExecutiveIds ?? this.salesExecutiveIds),
      salesSupervisorIds: clearSalesSupervisor ? null : (salesSupervisorIds ?? this.salesSupervisorIds),
      salesManagerIds: clearSalesManager ? null : (salesManagerIds ?? this.salesManagerIds),
      salesGeneralManagerIds: clearSalesGeneralManager ? null : (salesGeneralManagerIds ?? this.salesGeneralManagerIds),
      contactDetail: contactDetail ?? this.contactDetail,
      apptStartDate: clearApptDates ? null : (apptStartDate ?? this.apptStartDate),
      apptEndDate: clearApptDates ? null : (apptEndDate ?? this.apptEndDate),
      visitStartDate: clearVisitDates ? null : (visitStartDate ?? this.visitStartDate),
      visitEndDate: clearVisitDates ? null : (visitEndDate ?? this.visitEndDate),
      reserveStartDate: clearReserveDates ? null : (reserveStartDate ?? this.reserveStartDate),
      reserveEndDate: clearReserveDates ? null : (reserveEndDate ?? this.reserveEndDate),
      spStartDate: clearSpDates ? null : (spStartDate ?? this.spStartDate),
      spEndDate: clearSpDates ? null : (spEndDate ?? this.spEndDate),
      lostStartDate: clearLostDates ? null : (lostStartDate ?? this.lostStartDate),
      lostEndDate: clearLostDates ? null : (lostEndDate ?? this.lostEndDate),
      lastProject: clearProject ? null : (lastProject ?? this.lastProject),
      totalContacts: totalContacts ?? this.totalContacts,
      duplicateCheckContacts: duplicateCheckContacts ?? this.duplicateCheckContacts,
      sort: clearSort ? null : (sort ?? this.sort),
    );
  }

  @override
  List<Object?> get props => [
    status,
    contacts,
    errorMessage,
    currentPage,
    hasReachedMax,
    search,
    startDate,
    endDate,
    ownerIds,
    statusProspectIds,
    salesChannelIds,
    salesTeamIds,
    salesExecutiveIds,
    salesSupervisorIds,
    salesManagerIds,
    salesGeneralManagerIds,
    contactDetail,
    apptStartDate,
    apptEndDate,
    visitStartDate,
    visitEndDate,
    reserveStartDate,
    reserveEndDate,
    spStartDate,
    spEndDate,
    lostStartDate,
    lostEndDate,
    lastProject,
    totalContacts,
    duplicateCheckContacts,
    sort,
  ];
}
