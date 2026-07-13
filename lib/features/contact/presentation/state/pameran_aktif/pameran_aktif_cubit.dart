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
  int? _loadedUserId;

  PameranAktifCubit(this.repository) : super(PameranAktifInitial());

  Future<void> load({String? lokasiPameran, int? userId}) async {
    if (state is PameranAktifLoaded && _loadedLokasiPameran == lokasiPameran && _loadedUserId == userId) return;
    _loadedLokasiPameran = lokasiPameran;
    _loadedUserId = userId;
    final result = await repository.getPameranAktif(lokasiPameran: lokasiPameran, userId: userId);
    result.fold(
      (_) => emit(PameranAktifLoaded([])),
      (data) => emit(PameranAktifLoaded(data)),
    );
  }

  void reset() {
    _loadedLokasiPameran = null;
    _loadedUserId = null;
    emit(PameranAktifInitial());
  }
}
