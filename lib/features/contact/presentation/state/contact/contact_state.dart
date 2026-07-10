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
  final ContactEntity? contactDetail;
  final String? apptStartDate;
  final String? apptEndDate;
  final String? visitStartDate;
  final String? visitEndDate;
  final String? reserveStartDate;
  final String? reserveEndDate;
  final String? spStartDate;
  final String? spEndDate;
  final int? totalContacts;
  final List<ContactEntity> duplicateCheckContacts;

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
    this.contactDetail,
    this.apptStartDate,
    this.apptEndDate,
    this.visitStartDate,
    this.visitEndDate,
    this.reserveStartDate,
    this.reserveEndDate,
    this.spStartDate,
    this.spEndDate,
    this.totalContacts,
    this.duplicateCheckContacts = const [],
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
    bool clearSearch = false,
    bool clearDates = false,
    bool clearOwner = false,
    bool clearStatus = false,
    bool clearSalesChannel = false,
    bool clearSalesTeam = false,
    ContactEntity? contactDetail,
    String? apptStartDate,
    String? apptEndDate,
    String? visitStartDate,
    String? visitEndDate,
    String? reserveStartDate,
    String? reserveEndDate,
    String? spStartDate,
    String? spEndDate,
    bool clearApptDates = false,
    bool clearVisitDates = false,
    bool clearReserveDates = false,
    bool clearSpDates = false,
    int? totalContacts,
    List<ContactEntity>? duplicateCheckContacts,
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
      contactDetail: contactDetail ?? this.contactDetail,
      apptStartDate: clearApptDates ? null : (apptStartDate ?? this.apptStartDate),
      apptEndDate: clearApptDates ? null : (apptEndDate ?? this.apptEndDate),
      visitStartDate: clearVisitDates ? null : (visitStartDate ?? this.visitStartDate),
      visitEndDate: clearVisitDates ? null : (visitEndDate ?? this.visitEndDate),
      reserveStartDate: clearReserveDates ? null : (reserveStartDate ?? this.reserveStartDate),
      reserveEndDate: clearReserveDates ? null : (reserveEndDate ?? this.reserveEndDate),
      spStartDate: clearSpDates ? null : (spStartDate ?? this.spStartDate),
      spEndDate: clearSpDates ? null : (spEndDate ?? this.spEndDate),
      totalContacts: totalContacts ?? this.totalContacts,
      duplicateCheckContacts: duplicateCheckContacts ?? this.duplicateCheckContacts,
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
    contactDetail,
    apptStartDate,
    apptEndDate,
    visitStartDate,
    visitEndDate,
    reserveStartDate,
    reserveEndDate,
    spStartDate,
    spEndDate,
    totalContacts,
    duplicateCheckContacts,
  ];
}
