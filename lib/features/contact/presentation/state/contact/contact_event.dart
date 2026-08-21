import 'package:equatable/equatable.dart';
import '../../../domain/entities/contact/create_contact_params.dart';

abstract class ContactEvent extends Equatable {
  const ContactEvent();

  @override
  List<Object?> get props => [];
}

class FetchContactsEvent extends ContactEvent {
  final int page;
  final int perPage;
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
  final bool isRefresh;
  final bool clearSearch;
  final bool clearDates;
  final bool clearOwner;
  final bool clearStatus;
  final bool clearSalesChannel;
  final bool clearSalesTeam;
  final bool clearSalesExecutive;
  final bool clearSalesSupervisor;
  final bool clearSalesManager;
  final bool clearSalesGeneralManager;
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
  final bool clearApptDates;
  final bool clearVisitDates;
  final bool clearReserveDates;
  final bool clearSpDates;
  final bool clearLostDates;
  final bool clearProject;
  final String? sort;
  final bool clearSort;

  const FetchContactsEvent({
    this.page = 1,
    this.perPage = 10,
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
    this.isRefresh = false,
    this.clearSearch = false,
    this.clearDates = false,
    this.clearOwner = false,
    this.clearStatus = false,
    this.clearSalesChannel = false,
    this.clearSalesTeam = false,
    this.clearSalesExecutive = false,
    this.clearSalesSupervisor = false,
    this.clearSalesManager = false,
    this.clearSalesGeneralManager = false,
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
    this.clearApptDates = false,
    this.clearVisitDates = false,
    this.clearReserveDates = false,
    this.clearSpDates = false,
    this.clearLostDates = false,
    this.clearProject = false,
    this.sort,
    this.clearSort = false,
  });

  @override
  List<Object?> get props => [
    page,
    perPage,
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
    isRefresh,
    clearSearch,
    clearDates,
    clearOwner,
    clearStatus,
    clearSalesChannel,
    clearSalesTeam,
    clearSalesExecutive,
    clearSalesSupervisor,
    clearSalesManager,
    clearSalesGeneralManager,
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
    clearApptDates,
    clearVisitDates,
    clearReserveDates,
    clearSpDates,
    clearLostDates,
    clearProject,
    sort,
    clearSort,
  ];
}

class CreateContactEvent extends ContactEvent {
  final CreateContactParams params;

  const CreateContactEvent(this.params);

  @override
  List<Object?> get props => [params];
}

class UpdateContactEvent extends ContactEvent {
  final int contactId;
  final CreateContactParams params;

  const UpdateContactEvent(this.contactId, this.params);

  @override
  List<Object?> get props => [contactId, params];
}

class FetchContactDetailEvent extends ContactEvent {
  final int contactId;

  const FetchContactDetailEvent(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

class DeleteContactEvent extends ContactEvent {
  final int contactId;

  const DeleteContactEvent(this.contactId);

  @override
  List<Object?> get props => [contactId];
}
class ClearContactDetailEvent extends ContactEvent {}
class ClearContactsEvent extends ContactEvent {}
class FetchDuplicateCheckContactsEvent extends ContactEvent {
  const FetchDuplicateCheckContactsEvent();
}
class ResetContactFiltersEvent extends ContactEvent {
  const ResetContactFiltersEvent();
}

