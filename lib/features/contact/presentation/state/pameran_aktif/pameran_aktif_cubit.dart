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
  String? _loadedLokasiPameran;

  PameranAktifCubit(this.repository) : super(PameranAktifInitial());

  Future<void> load({String? lokasiPameran}) async {
    if (state is PameranAktifLoaded && _loadedLokasiPameran == lokasiPameran) return;
    _loadedLokasiPameran = lokasiPameran;
    final result = await repository.getPameranAktif(lokasiPameran: lokasiPameran);
    result.fold(
      (_) => emit(PameranAktifLoaded([])),
      (data) => emit(PameranAktifLoaded(data)),
    );
  }
}
