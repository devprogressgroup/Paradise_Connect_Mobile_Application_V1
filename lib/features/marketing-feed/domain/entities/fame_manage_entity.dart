import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

/// Hak akses kelola Wall of Fame dari backend (t_feed_fame_perm), bukan dari permission app.
class FameAccessEntity {
  final bool canEdit;
  final bool canCreateProgram;

  const FameAccessEntity({
    required this.canEdit,
    required this.canCreateProgram,
  });
}

/// Satu juara di dalam satu kartu Wall of Fame.
class FameAdminWinnerEntity {
  final int userId;
  final String name;
  final int ranking;

  /// Teks peringkat dari admin (mis. "1+"). Null = pakai [ranking].
  final String? peringkatLabel;
  final String? posisiLabel;
  final String? timLabel;

  const FameAdminWinnerEntity({
    required this.userId,
    required this.name,
    required this.ranking,
    this.peringkatLabel,
    this.posisiLabel,
    this.timLabel,
  });

  String get rankText => (peringkatLabel ?? '').trim().isNotEmpty
      ? peringkatLabel!.trim()
      : '$ranking';
}

/// Kartu Wall of Fame (versi admin): satu kategori dengan satu atau lebih juara dan satu poster opsional.
class FameAdminCardEntity {
  final int id;
  final String kategori;
  final String? caption;
  final String status; // draft | scheduled | published
  final DateTime? publishAt;
  final DateTime? publishedAt;
  final int? mediaId;
  final String? mediaType;
  final List<FameAdminWinnerEntity> winners;

  const FameAdminCardEntity({
    required this.id,
    required this.kategori,
    this.caption,
    required this.status,
    this.publishAt,
    this.publishedAt,
    this.mediaId,
    this.mediaType,
    this.winners = const [],
  });

  bool get hasPoster => mediaId != null;
}

/// Program beserta kartunya, untuk halaman kelola.
class FameManageProgramEntity {
  final int id;
  final String namaProgram;
  final String? periodeLabel;
  final List<FameAdminCardEntity> cards;

  const FameManageProgramEntity({
    required this.id,
    required this.namaProgram,
    this.periodeLabel,
    this.cards = const [],
  });
}

/// Sales yang bisa dipilih sebagai juara.
class FameCandidateEntity {
  final int userId;
  final String name;
  final String? position;
  final String? team;
  final String? info;

  const FameCandidateEntity({
    required this.userId,
    required this.name,
    this.position,
    this.team,
    this.info,
  });
}

/// Isi form untuk membuat atau mengubah kartu. [programId] diisi kalau program sudah ada,
/// [namaProgram] kalau program baru (hanya untuk pengguna dengan can_create_program).
class FameCardParams {
  final int? programId;
  final String? namaProgram;
  final String? periodeLabel;
  final String kategori;
  final String? caption;

  /// draft | scheduled | published
  final String status;

  /// Waktu tayang jam dinding WIB (wajib kalau scheduled).
  final DateTime? publishAt;
  final List<FameWinnerInput> winners;
  final FeedMediaEntity? poster;

  const FameCardParams({
    this.programId,
    this.namaProgram,
    this.periodeLabel,
    required this.kategori,
    this.caption,
    required this.status,
    this.publishAt,
    required this.winners,
    this.poster,
  });
}

class FameWinnerInput {
  final int userId;

  /// Angka peringkat (urutan & seri), diambil dari angka di depan label.
  final int ranking;

  /// Teks peringkat yang tampil (mis. "1+"). Null = sama dengan angka.
  final String? peringkatLabel;
  final String? posisiLabel;
  final String? timLabel;

  const FameWinnerInput({
    required this.userId,
    required this.ranking,
    this.peringkatLabel,
    this.posisiLabel,
    this.timLabel,
  });
}
