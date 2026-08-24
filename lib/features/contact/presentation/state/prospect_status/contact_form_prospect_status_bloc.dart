import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/prospect/get_contact_form_prospect_statuses_usecase.dart';
import 'prospect_status_event.dart';
import 'prospect_status_state.dart';

class ContactFormProspectStatusBloc extends Bloc<ProspectStatusEvent, ProspectStatusState> {
  final GetContactFormProspectStatusesUseCase getContactFormProspectStatusesUseCase;

  ContactFormProspectStatusBloc({required this.getContactFormProspectStatusesUseCase}) : super(const ProspectStatusState()) {
    on<FetchProspectStatusesEvent>(_onFetchProspectStatuses);
  }

  Future<void> _onFetchProspectStatuses(
    FetchProspectStatusesEvent event,
    Emitter<ProspectStatusState> emit,
  ) async {
    emit(state.copyWith(status: ProspectStatusEnum.loading));

    final result = await getContactFormProspectStatusesUseCase(contactId: event.contactId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProspectStatusEnum.error,
        errorMessage: failure,
      )),
      (statuses) => emit(state.copyWith(
        status: ProspectStatusEnum.loaded,
        statuses: statuses,
      )),
    );
  }
}
