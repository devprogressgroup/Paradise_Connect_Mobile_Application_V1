import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/contact/domain/usecases/contact/update_contact_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/contact/delete_contact_usecase.dart';

import '../../../domain/usecases/contact/get_contacts_usecase.dart';
import '../../../domain/usecases/contact/create_contact_usecase.dart';
import '../../../domain/usecases/contact/get_contact_detail_usecase.dart';
import 'contact_event.dart';
import 'contact_state.dart';

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  final GetContactsUseCase getContactsUseCase;
  final CreateContactUseCase createContactUseCase;
  final UpdateContactUseCase updateContactUseCase;
  final DeleteContactUseCase deleteContactUseCase;
  final GetContactDetailUseCase getContactDetailUseCase;

  ContactBloc({
    required this.getContactsUseCase,
    required this.createContactUseCase,
    required this.updateContactUseCase,
    required this.deleteContactUseCase,
    required this.getContactDetailUseCase,
  }) : super(const ContactState()) {
    on<FetchContactsEvent>(_onFetchContacts);
    on<CreateContactEvent>(_onCreateContact);
    on<FetchContactDetailEvent>(_onFetchContactDetail);
    on<UpdateContactEvent>(_onUpdateContact);
    on<DeleteContactEvent>(_onDeleteContact);
    on<ClearContactDetailEvent>((event, emit) => emit(state.copyWith(
          contactDetail: null,
          status: ContactStatus.initial,
        )));
    on<ClearContactsEvent>((event, emit) => emit(const ContactState()));
    on<ResetContactFiltersEvent>((event, emit) => emit(state.copyWith(
          clearDates: true,
          clearOwner: true,
          clearStatus: true,
        )));
  }



  Future<void> _onFetchContacts(
    FetchContactsEvent event,
    Emitter<ContactState> emit,
  ) async {
    if (event.isRefresh) {
      emit(
        state.copyWith(
          status: ContactStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
          contacts: [],
          search: event.search,
          startDate: event.startDate,
          endDate: event.endDate,
          ownerIds: event.ownerIds,
          statusProspectIds: event.statusProspectIds,
          clearSearch: event.clearSearch,
          clearDates: event.clearDates,
          clearOwner: event.clearOwner,
          clearStatus: event.clearStatus,
        ),
      );
    } else {
      if (state.hasReachedMax && state.status == ContactStatus.loaded) return;
      if (state.status == ContactStatus.initial) {
        emit(
          state.copyWith(
            status: ContactStatus.loading,
            search: event.search,
            startDate: event.startDate,
            endDate: event.endDate,
            ownerIds: event.ownerIds,
            statusProspectIds: event.statusProspectIds,
          ),
        );
      }
    }

    final currentPage = event.isRefresh ? 1 : state.currentPage;

    final result = await getContactsUseCase(
      page: currentPage,
      perPage: event.perPage,
      search: event.clearSearch ? null : (event.search ?? state.search),
      startDate: event.clearDates ? null : (event.startDate ?? state.startDate),
      endDate: event.clearDates ? null : (event.endDate ?? state.endDate),
      ownerIds: event.clearOwner ? null : (event.ownerIds ?? state.ownerIds),
      statusProspectIds: event.clearStatus ? null : (event.statusProspectIds ?? state.statusProspectIds),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: ContactStatus.error, errorMessage: failure),
      ),
      (response) {
        final isLastPage = response.nextPageUrl == null;
        emit(
          state.copyWith(
            status: ContactStatus.loaded,
            contacts: event.isRefresh
                ? response.data
                : [...state.contacts, ...response.data],
            hasReachedMax: isLastPage,
            currentPage: currentPage + 1,
          ),
        );
      },
    );
  }

  Future<void> _onCreateContact(
    CreateContactEvent event,
    Emitter<ContactState> emit,
  ) async {
    emit(state.copyWith(status: ContactStatus.creating));

    final result = await createContactUseCase(event.params);

    result.fold(
      (failure) => emit(
        state.copyWith(status: ContactStatus.error, errorMessage: failure),
      ),
      (contact) => emit(
        state.copyWith(status: ContactStatus.createSuccess, contactDetail: contact),
      ),
    );
  }

  Future<void> _onFetchContactDetail(
    FetchContactDetailEvent event,
    Emitter<ContactState> emit,
  ) async {
    emit(state.copyWith(status: ContactStatus.loadingDetail));

    final result = await getContactDetailUseCase(event.contactId);

    result.fold(
      (failure) => emit(
        state.copyWith(status: ContactStatus.error, errorMessage: failure),
      ),
      (contact) => emit(
        state.copyWith(
          status: ContactStatus.detailLoaded,
          contactDetail: contact,
        ),
      ),
    );
  }

  Future<void> _onUpdateContact(
    UpdateContactEvent event,
    Emitter<ContactState> emit,
  ) async {
    emit(state.copyWith(status: ContactStatus.creating));

    final result = await updateContactUseCase(event.contactId, event.params);

    result.fold(
      (failure) => emit(
        state.copyWith(status: ContactStatus.error, errorMessage: failure),
      ),
      (contact) => emit(state.copyWith(status: ContactStatus.updateSuccess, contactDetail: contact)),
    );
  }

  Future<void> _onDeleteContact(
    DeleteContactEvent event,
    Emitter<ContactState> emit,
  ) async {
    emit(state.copyWith(status: ContactStatus.deleting));

    final result = await deleteContactUseCase(event.contactId);

    result.fold(
      (failure) => emit(
        state.copyWith(status: ContactStatus.error, errorMessage: failure),
      ),
      (_) {
        emit(state.copyWith(status: ContactStatus.deleteSuccess));
        add(const FetchContactsEvent(isRefresh: true));
      },
    );
  }
}
