import 'package:progress_group/features/marketing-feed/domain/entities/fame_program_entity.dart';

/// Membaca respons GET /marketing-feed/wall-of-fame/programs (data.items).
/// Bentuk: items[] = { id, nama_program, periode_label, categories[] = { kategori, entries[] } }.
/// Entry: { id, program_id, program, periode, kategori, ranking, posisi_label, caption, name, initials,
///          photo_url, media{type,url}|null, is_pinned, published_at }.
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
                  FameEntryEntity(
                    id: (e['id'] as num).toInt(),
                    programId: (e['program_id'] as num).toInt(),
                    programName: (e['program'] ?? raw['nama_program'] ?? '') as String,
                    periodeLabel: e['periode'] as String? ?? raw['periode_label'] as String?,
                    kategori: (e['kategori'] ?? '') as String,
                    ranking: (e['ranking'] as num).toInt(),
                    posisiLabel: e['posisi_label'] as String?,
                    caption: e['caption'] as String?,
                    name: (e['name'] ?? '') as String,
                    initials: (e['initials'] ?? '') as String,
                    photoUrl: e['photo_url'] as String?,
                    mediaType: (e['media'] as Map?)?['type'] as String?,
                    mediaUrl: (e['media'] as Map?)?['url'] as String?,
                    isPinned: e['is_pinned'] == true,
                    publishedAt: e['published_at'] == null ? null : DateTime.tryParse(e['published_at'] as String),
                  ),
              ],
            ),
        ],
      ),
  ];
}
