/// Satu juara (orang) di dalam kartu Wall of Fame.
class FameWinnerEntity {
  final int userId;
  final String name;
  final String initials;
  final String? photoUrl;
  final int ranking;

  /// Teks peringkat yang tampil (mis. "1+"). Null = pakai angka [ranking].
  final String? rankLabel;
  final String? posisiLabel;
  final String? timLabel;

  /// True kalau peringkat ini dimiliki lebih dari satu juara di kartu yang sama (seri).
  final bool isSeri;

  const FameWinnerEntity({
    required this.userId,
    required this.name,
    required this.initials,
    this.photoUrl,
    required this.ranking,
    this.rankLabel,
    this.posisiLabel,
    this.timLabel,
    this.isSeri = false,
  });

  /// Teks peringkat untuk ditampilkan: label dari admin kalau ada, kalau tidak angka ranking.
  String get rankText =>
      (rankLabel ?? '').trim().isNotEmpty ? rankLabel!.trim() : '$ranking';
}

/// Kartu Wall of Fame: satu kategori dalam satu program, dengan poster (media) dan beberapa juara.
/// Nama kelas dipertahankan dari model lama; isinya sekarang kartu, bukan satu orang.
class FameEntryEntity {
  final int id;
  final int programId;
  final String programName;
  final String? periodeLabel;
  final String kategori;
  final String? caption;
  final bool isPinned;

  /// Waktu tayang kartu. Dipakai untuk mengurutkan bersama kiriman lain (bukan selalu di atas).
  final DateTime? publishedAt;

  /// Pembuat kartu (admin yang memasukkan juara). Ditampilkan sebagai header kartu.
  final String creatorName;
  final String creatorInitials;
  final String? creatorPhotoUrl;

  /// Poster kartu (gambar atau video). Null kalau belum diunggah.
  final String? mediaType;
  final String? mediaUrl;

  /// Juara di kartu ini, sudah diurutkan menurut peringkat.
  final List<FameWinnerEntity> winners;
  final int juaraCount;

  /// Ringkasan dari server, mis. "3 JUARA (#1 SERI, #1 SERI, #3)". Ditampilkan sebagai pita di atas kartu.
  final String summary;

  /// Peringkat terbaik di kartu (1 = juara utama). Dipakai untuk gaya kartu juara.
  final int topRank;

  const FameEntryEntity({
    required this.id,
    required this.programId,
    required this.programName,
    this.periodeLabel,
    required this.kategori,
    this.caption,
    this.isPinned = false,
    this.publishedAt,
    this.creatorName = 'Admin',
    this.creatorInitials = 'A',
    this.creatorPhotoUrl,
    this.mediaType,
    this.mediaUrl,
    this.winners = const [],
    this.juaraCount = 0,
    this.summary = '',
    this.topRank = 0,
  });

  bool get isChampion => topRank == 1;
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
