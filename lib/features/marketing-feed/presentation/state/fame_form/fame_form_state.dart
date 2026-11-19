import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';

/// State form Wall of Fame: daftar sales (kandidat juara) dan status simpan.
class FameFormState {
  final bool loadingCandidates;
  final List<FameCandidateEntity> candidates;
  final bool saving;
  final String? errorMessage;

  const FameFormState({
    this.loadingCandidates = false,
    this.candidates = const [],
    this.saving = false,
    this.errorMessage,
  });

  FameFormState copyWith({
    bool? loadingCandidates,
    List<FameCandidateEntity>? candidates,
    bool? saving,
    String? errorMessage,
  }) {
    return FameFormState(
      loadingCandidates: loadingCandidates ?? this.loadingCandidates,
      candidates: candidates ?? this.candidates,
      saving: saving ?? this.saving,
      errorMessage: errorMessage,
    );
  }
}
