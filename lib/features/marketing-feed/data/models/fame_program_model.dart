import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';

DateTime? _parseDate(Object? raw) =>
    raw == null ? null : DateTime.tryParse(raw as String);

FameWinnerEntity _parseWinner(Map<dynamic, dynamic> w) => FameWinnerEntity(
  userId: (w['user_id'] as num?)?.toInt() ?? 0,
  name: (w['name'] ?? '') as String,
  initials: (w['initials'] ?? '') as String,
  photoUrl: w['photo_url'] as String?,
  ranking: (w['ranking'] as num).toInt(),
  rankLabel: w['rank_label'] as String?,
  posisiLabel: w['posisi_label'] as String?,
  timLabel: w['tim_label'] as String?,
  isSeri: w['is_seri'] == true,
);

/// Satu kartu Wall of Fame (bentuk sama dengan Home). Dipakai juga oleh halaman kelola.
FameEntryEntity parseFameEntry(
  Map<dynamic, dynamic> e,
  Map<dynamic, dynamic> program,
) {
  final creator = (e['creator'] as Map?) ?? const {};
  final media = e['media'] as Map?;
  final winners = [
    for (final w in (e['winners'] as List? ?? const [])) _parseWinner(w as Map),
  ];
  return FameEntryEntity(
    id: (e['id'] as num).toInt(),
    programId: (e['program_id'] as num).toInt(),
    programName: (e['program'] ?? program['nama_program'] ?? '') as String,
    periodeLabel:
        e['periode'] as String? ?? program['periode_label'] as String?,
    kategori: (e['kategori'] ?? '') as String,
    caption: e['caption'] as String?,
    isPinned: e['is_pinned'] == true,
    publishedAt: _parseDate(e['published_at']),
    creatorName: (creator['name'] ?? 'Admin') as String,
    creatorInitials: (creator['initials'] ?? 'A') as String,
    creatorPhotoUrl: creator['photo_url'] as String?,
    mediaType: media?['type'] as String?,
    mediaUrl: media?['url'] as String?,
    winners: winners,
    juaraCount: (e['juara_count'] as num?)?.toInt() ?? winners.length,
    summary: (e['summary'] ?? '') as String,
    topRank:
        (e['top_rank'] as num?)?.toInt() ??
        (winners.isEmpty ? 0 : winners.first.ranking),
    likeCount: ((e['counts'] as Map?)?['likes'] as num?)?.toInt() ?? 0,
    dislikeCount: ((e['counts'] as Map?)?['dislikes'] as num?)?.toInt() ?? 0,
    commentCount: ((e['counts'] as Map?)?['comments'] as num?)?.toInt() ?? 0,
    myReaction: switch (e['my_reaction'] as String?) {
      'like' => FeedReaction.like,
      'dislike' => FeedReaction.dislike,
      _ => FeedReaction.none,
    },
  );
}

/// Membaca respons GET /marketing-feed/wall-of-fame/programs (data.items).
/// items[] = { id, nama_program, periode_label, categories[] = { kategori, entries[] = kartu } }.
List<FameProgramEntity> parseFamePrograms(List<dynamic> items) {
  return [
    for (final raw in items)
      FameProgramEntity(
        id: (raw['id'] as num).toInt(),
        namaProgram: (raw['nama_program'] ?? '') as String,
        periodeLabel: raw['periode_label'] as String?,
        categories: [
          for (final c in (raw['categories'] as List? ?? const []))
            FameCategoryEntity(
              kategori: (c['kategori'] ?? '') as String,
              entries: [
                for (final e in (c['entries'] as List? ?? const []))
                  parseFameEntry(e as Map, raw as Map),
              ],
            ),
        ],
      ),
  ];
}
