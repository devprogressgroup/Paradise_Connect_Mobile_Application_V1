import 'package:progress_group/features/marketing-feed/data/models/fame_program_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/fame_manage_entity.dart';

/// Parser respons kelola Wall of Fame (wall-of-fame/access, manage, candidates, dan kartu).
/// publish_at / published_at dikirim server sebagai 'Y-m-d H:i:s' (jam WIB). Disimpan sebagai jam dinding
/// tanpa konversi, sama dengan konvensi FeedScheduleField.

FameAccessEntity parseFameAccess(Map<String, dynamic> raw) => FameAccessEntity(
  canEdit: raw['can_edit'] == true,
  canCreateProgram: raw['can_create_program'] == true,
);

List<FameManageProgramEntity> parseFameManage(List<dynamic> items) => [
  for (final raw in items)
    FameManageProgramEntity(
      id: (raw['id'] as num).toInt(),
      namaProgram: (raw['nama_program'] ?? '') as String,
      periodeLabel: raw['periode_label'] as String?,
      cards: [
        for (final c in (raw['entries'] as List? ?? const []))
          parseFameAdminCard(Map<String, dynamic>.from(c as Map)),
      ],
    ),
];

FameAdminCardEntity parseFameAdminCard(Map<String, dynamic> raw) {
  final media = raw['media'] as Map?;
  return FameAdminCardEntity(
    id: (raw['id'] as num).toInt(),
    kategori: (raw['kategori'] ?? '') as String,
    caption: raw['caption'] as String?,
    status: (raw['status'] ?? 'draft') as String,
    publishAt: _wall(raw['publish_at']),
    publishedAt: _wall(raw['published_at']),
    mediaId: (media?['id'] as num?)?.toInt(),
    mediaType: media?['type'] as String?,
    winners: [
      for (final w in (raw['winners'] as List? ?? const []))
        FameAdminWinnerEntity(
          userId: ((w as Map)['user_id'] as num).toInt(),
          name: (w['name'] ?? '') as String,
          ranking: (w['ranking'] as num).toInt(),
          peringkatLabel: w['peringkat_label'] as String?,
          posisiLabel: w['posisi_label'] as String?,
          timLabel: w['tim_label'] as String?,
        ),
    ],
    // Bentuk Home hanya ada di daftar kelola (punya program_id); respons detail/simpan tidak punya.
    entry: raw['program_id'] == null
        ? null
        : parseFameEntry(raw, {'nama_program': raw['program']}),
  );
}

List<FameCandidateEntity> parseFameCandidates(List<dynamic> items) => [
  for (final raw in items)
    FameCandidateEntity(
      userId: (raw['user_id'] as num).toInt(),
      name: (raw['name'] ?? '') as String,
      position: raw['position'] as String?,
      team: raw['team'] as String?,
      info: raw['info'] as String?,
    ),
];

DateTime? _wall(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  final p = DateTime.tryParse(raw);
  if (p == null) return null;
  return DateTime.utc(p.year, p.month, p.day, p.hour, p.minute);
}
