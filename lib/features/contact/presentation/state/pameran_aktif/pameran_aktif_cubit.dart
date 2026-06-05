import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/contact/domain/entities/pameran/pameran_aktif_entity.dart';
import 'package:progress_group/features/contact/domain/repositories/contact_repository.dart';

abstract class PameranAktifState {}

class PameranAktifInitial extends PameranAktifState {}

class PameranAktifLoaded extends PameranAktifState {
  final List<PameranAktifEntity> data;
  PameranAktifLoaded(this.data);
}

class PameranAktifCubit extends Cubit<PameranAktifState> {
  final ContactRepository repository;

  PameranAktifCubit(this.repository) : super(PameranAktifInitial());

  Future<void> load() async {
    if (state is PameranAktifLoaded) return;
    final result = await repository.getPameranAktif();
    result.fold(
      (_) => emit(PameranAktifLoaded([])),
      (data) => emit(PameranAktifLoaded(data)),
    );
  }
}
