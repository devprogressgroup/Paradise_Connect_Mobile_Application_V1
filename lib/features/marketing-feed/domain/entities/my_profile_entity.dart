import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

/// Profil sales di Marketing Feed: identitas, hitungan kiriman tayang, suka, komentar,
/// dan satu halaman kiriman untuk tab yang dipilih ([tab]).
class MyProfileEntity {
  final int id;
  final String name;
  final String initials;
  final String? photoUrl;
  final String subtitle;
  final int postCount;
  final int likeCount;
  final int commentCount;

  /// Tab yang dipakai server: semua | reels | tautan.
  final String tab;

  /// Jumlah kiriman per tab, mis. {semua: 16, reels: 2, tautan: 1}.
  final Map<String, int> counts;

  /// Kartu untuk halaman [currentPage] pada tab [tab] (format sama dengan feed Home).
  final List<FeedPostEntity> items;
  final int currentPage;
  final int total;
  final bool hasMore;

  const MyProfileEntity({
    required this.id,
    required this.name,
    required this.initials,
    this.photoUrl,
    required this.subtitle,
    required this.postCount,
    required this.likeCount,
    required this.commentCount,
    this.tab = 'semua',
    this.counts = const {},
    this.items = const [],
    this.currentPage = 1,
    this.total = 0,
    this.hasMore = false,
  });
}
