import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';
import 'fame_form_state.dart';

/// Form kartu Wall of Fame (admin mobile): memuat kandidat sales dan menyimpan kartu beserta juaranya.
class FameFormCubit extends Cubit<FameFormState> {
  final MarketingFeedRepository repository;

  FameFormCubit({required this.repository}) : super(const FameFormState());

  Future<void> loadCandidates() async {
    if (state.candidates.isNotEmpty || state.loadingCandidates) return;
    emit(state.copyWith(loadingCandidates: true));
    final result = await repository.getFameCandidates();
    if (isClosed) return;
    result.fold(
      (m) => emit(state.copyWith(loadingCandidates: false, errorMessage: m)),
      (list) =>
          emit(state.copyWith(loadingCandidates: false, candidates: list)),
    );
  }

  /// Balikan: pesan error, atau null kalau tersimpan. [cardId] null = kartu baru.
  Future<String?> save(FameCardParams params, {int? cardId}) async {
    emit(state.copyWith(saving: true));
    final result = await repository.saveFameCard(params, cardId: cardId);
    if (isClosed) return null;
    String? error;
    result.fold((m) => error = m, (_) {});
    emit(state.copyWith(saving: false, errorMessage: error));
    return error;
  }
}
