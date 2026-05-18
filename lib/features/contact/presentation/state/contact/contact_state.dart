import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';

enum ContactStatus {
  initial,
  loading,
  loaded,
  error,
  creating,
  createSuccess,
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
  final ContactEntity? contactDetail;

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
    this.contactDetail,
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
    bool clearSearch = false,
    bool clearDates = false,
    bool clearOwner = false,
    bool clearStatus = false,
    ContactEntity? contactDetail,
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
      statusProspectIds: clearStatus
          ? null
          : (statusProspectIds ?? this.statusProspectIds),
      contactDetail: contactDetail ?? this.contactDetail,
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
    contactDetail,
  ];
}
