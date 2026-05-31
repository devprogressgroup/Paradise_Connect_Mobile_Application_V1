import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/contact/get_contact_properties_usecase.dart';
import 'contact_properties_event.dart';
import 'contact_properties_state.dart';

class ContactPropertiesBloc
    extends Bloc<ContactPropertiesEvent, ContactPropertiesState> {
  final GetContactPropertiesUseCase getContactPropertiesUseCase;
  ContactPropertiesBloc({required this.getContactPropertiesUseCase})
    : super(const ContactPropertiesState()) {
    on<FetchContactPropertiesEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchContactPropertiesEvent event,
    Emitter<ContactPropertiesState> emit,
  ) async {
    emit(state.copyWith(status: ContactPropertiesStatus.loading));
    final result = await getContactPropertiesUseCase();
    result.fold(
      (l) => emit(
        state.copyWith(status: ContactPropertiesStatus.error, errorMessage: l),
      ),
      (r) {
        print('[ContactProperties] groups: ${r.map((g) => {'name': g.name, 'label': g.label, 'properties': g.properties.map((p) => {'id': p.propertyId, 'label': p.label, 'type': p.fieldType}).toList()}).toList()}');
        emit(state.copyWith(status: ContactPropertiesStatus.loaded, groups: r));
      },
    );
  }
}
