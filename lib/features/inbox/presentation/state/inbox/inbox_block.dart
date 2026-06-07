import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/inbox/domain/usecases/inbox_contact_usecase.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_event.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_statte.dart';


class InboxContactBloc extends Bloc<InboxContactEvent, InboxContactState> {
  final GetInboxContactsUsecase getContacts;

  InboxContactBloc(this.getContacts): super(InboxContactInitial()) {
    on<GetInboxContactsEvent>(_onGetContacts);
  }

  Future<void> _onGetContacts(
    GetInboxContactsEvent event,
    Emitter<InboxContactState> emit,
  ) async {
    final currentState = state;
    if (!event.isLoadMore) {
      emit(InboxContactLoading());
    }

    try {
      if (event.isLoadMore && currentState is InboxContactLoaded) {
        emit(InboxContactLoaded(
          currentState.contacts,
          currentState.groups,
          isFetchingMore: true,
        ));
      }

      final (contacts, groups) = await getContacts(
        search: event.search,
        cPage: event.cPage,
        gPage: event.gPage,
        salesExecutiveIds: event.salesExecutiveIds,
        statusProspectId: event.statusProspectId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      if (event.isLoadMore && currentState is InboxContactLoaded) {
        emit(InboxContactLoaded(
          currentState.contacts + contacts,
          currentState.groups + groups,
          isFetchingMore: false,
        ));
      } else {
        emit(InboxContactLoaded(contacts, groups));
      }
    } catch (e) {
      emit(InboxContactError(cleanErrorMessage(e)));
    }
  }
}