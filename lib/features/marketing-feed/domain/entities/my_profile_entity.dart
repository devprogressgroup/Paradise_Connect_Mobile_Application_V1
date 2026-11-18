/// Profil sales sendiri di Marketing Feed: identitas, hitungan kiriman tayang, suka, komentar, dan daftarnya.
class MyProfileEntity {
  final int id;
  final String name;
  final String initials;
  final String? photoUrl;
  final String subtitle;
  final int postCount;
  final int likeCount;
  final int commentCount;
  final List<MyProfilePostEntity> posts;

  const MyProfileEntity({
    required this.id,
    required this.name,
    required this.initials,
    this.photoUrl,
    required this.subtitle,
    required this.postCount,
    required this.likeCount,
    required this.commentCount,
    required this.posts,
  });
}

/// Satu kiriman tayang di profil. [thumbUrl] = foto/video pertama (null kalau hanya teks).
class MyProfilePostEntity {
  final int id;
  final String type;
  final String? text;
  final String? thumbUrl;
  final String? thumbKind;
  final int likes;
  final int comments;
  final bool isProfilePinned;
  final DateTime publishedAt;

  const MyProfilePostEntity({
    required this.id,
    required this.type,
    this.text,
    this.thumbUrl,
    this.thumbKind,
    required this.likes,
    required this.comments,
    required this.isProfilePinned,
    required this.publishedAt,
  });
}
