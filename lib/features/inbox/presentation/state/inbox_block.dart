import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/inbox/domain/usecases/inbox_contact_usecase.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox_event.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox_statte.dart';


class InboxContactBloc extends Bloc<InboxContactEvent, InboxContactState> {
  final GetInboxContactsUsecase getContacts;

  InboxContactBloc(this.getContacts): super(InboxContactInitial()) {
    on<GetInboxContactsEvent>(_onGetContacts);
  }

  Future<void> _onGetContacts(
    GetInboxContactsEvent event,
    Emitter<InboxContactState> emit,
  ) async {
    emit(InboxContactLoading());

    try {
      final (contacts, groups) = await getContacts(
        search: event.search,
        cPage: event.cPage,
        gPage: event.gPage,
      );
      emit(InboxContactLoaded(contacts, groups));
    } catch (e) {
      emit(InboxContactError(e.toString()));
    }
  }
}