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
  final bool isRefresh;
  final bool clearSearch;
  final bool clearDates;
  final bool clearOwner;
  final bool clearStatus;
  final bool clearSalesChannel;
  final bool clearSalesTeam;
  final String? apptStartDate;
  final String? apptEndDate;
  final String? visitStartDate;
  final String? visitEndDate;
  final String? reserveStartDate;
  final String? reserveEndDate;
  final String? spStartDate;
  final String? spEndDate;
  final bool clearApptDates;
  final bool clearVisitDates;
  final bool clearReserveDates;
  final bool clearSpDates;
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
    this.isRefresh = false,
    this.clearSearch = false,
    this.clearDates = false,
    this.clearOwner = false,
    this.clearStatus = false,
    this.clearSalesChannel = false,
    this.clearSalesTeam = false,
    this.apptStartDate,
    this.apptEndDate,
    this.visitStartDate,
    this.visitEndDate,
    this.reserveStartDate,
    this.reserveEndDate,
    this.spStartDate,
    this.spEndDate,
    this.clearApptDates = false,
    this.clearVisitDates = false,
    this.clearReserveDates = false,
    this.clearSpDates = false,
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
    isRefresh,
    clearSearch,
    clearDates,
    clearOwner,
    clearStatus,
    clearSalesChannel,
    clearSalesTeam,
    apptStartDate,
    apptEndDate,
    visitStartDate,
    visitEndDate,
    reserveStartDate,
    reserveEndDate,
    spStartDate,
    spEndDate,
    clearApptDates,
    clearVisitDates,
    clearReserveDates,
    clearSpDates,
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

