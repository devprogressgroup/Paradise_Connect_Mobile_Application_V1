/// Wall of Fame baru (model program > kategori > peringkat). Satu entry = satu kartu per orang.
class FameEntryEntity {
  final int id;
  final int programId;
  final String programName;
  final String? periodeLabel;
  final String kategori;
  final int ranking;
  final String? posisiLabel;
  final String? caption;
  final String name;
  final String initials;
  final String? photoUrl;
  final String? mediaType;
  final String? mediaUrl;
  final bool isPinned;
  /// Waktu tayang juara. Dipakai untuk mengurutkan bersama kiriman lain (bukan selalu di atas).
  final DateTime? publishedAt;

  const FameEntryEntity({
    required this.id,
    required this.programId,
    required this.programName,
    this.periodeLabel,
    required this.kategori,
    required this.ranking,
    this.posisiLabel,
    this.caption,
    required this.name,
    required this.initials,
    this.photoUrl,
    this.mediaType,
    this.mediaUrl,
    this.isPinned = false,
    this.publishedAt,
  });

  bool get isChampion => ranking == 1;
}

class FameCategoryEntity {
  final String kategori;
  final List<FameEntryEntity> entries;

  const FameCategoryEntity({required this.kategori, required this.entries});
}

class FameProgramEntity {
  final int id;
  final String namaProgram;
  final String? periodeLabel;
  final List<FameCategoryEntity> categories;

  const FameProgramEntity({
    required this.id,
    required this.namaProgram,
    this.periodeLabel,
    required this.categories,
  });
}
