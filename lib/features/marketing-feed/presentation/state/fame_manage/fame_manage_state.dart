import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';

enum FameManageStatus { initial, loading, loaded, error }

/// State halaman kelola Wall of Fame. [access] null sebelum hak akses dimuat.
class FameManageState {
  final FameManageStatus status;
  final FameAccessEntity? access;
  final List<FameManageProgramEntity> programs;
  final String? errorMessage;

  /// Aksi (ubah status, hapus, unggah poster) sedang berjalan.
  final bool busy;

  const FameManageState({
    this.status = FameManageStatus.initial,
    this.access,
    this.programs = const [],
    this.errorMessage,
    this.busy = false,
  });

  FameManageState copyWith({
    FameManageStatus? status,
    FameAccessEntity? access,
    List<FameManageProgramEntity>? programs,
    String? errorMessage,
    bool? busy,
  }) {
    return FameManageState(
      status: status ?? this.status,
      access: access ?? this.access,
      programs: programs ?? this.programs,
      errorMessage: errorMessage,
      busy: busy ?? this.busy,
    );
  }
}
