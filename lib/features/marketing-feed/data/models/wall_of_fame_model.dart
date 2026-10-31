import 'package:progress_group/features/marketing-feed/data/models/feed_post_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';

class WallOfFameEntryModel extends WallOfFameEntryEntity {
  const WallOfFameEntryModel({
    super.id,
    required super.name,
    super.initials,
    super.info,
    super.highlight,
    super.photoUrl,
    super.media,
  });

  factory WallOfFameEntryModel.fromJson(Map<String, dynamic> json) {
    final mediaMap = json['media'] as Map<String, dynamic>?;
    return WallOfFameEntryModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '-',
      initials: json['initials'] as String?,
      info: json['info'] as String?,
      highlight: json['highlight'] as String?,
      photoUrl: json['photo_url'] as String?,
      media: mediaMap != null ? FeedMediaModel.fromJson(mediaMap) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (initials != null) 'initials': initials,
    if (info != null) 'info': info,
    if (highlight != null) 'highlight': highlight,
    if (photoUrl != null) 'photo_url': photoUrl,
    if (media != null) 'media': (media as FeedMediaModel).toJson(),
  };
}

class WallOfFameLevelModel extends WallOfFameLevelEntity {
  const WallOfFameLevelModel({
    required super.level,
    required super.champion,
    super.runnersUp,
  });

  factory WallOfFameLevelModel.fromJson(Map<String, dynamic> json) {
    // If json has "champion", use it (legacy/dummy format)
    if (json.containsKey('champion')) {
      return WallOfFameLevelModel(
        level: json['level'] as String? ?? '',
        champion: WallOfFameEntryModel.fromJson(json['champion'] as Map<String, dynamic>? ?? const {}),
        runnersUp: (json['runners_up'] as List<dynamic>? ?? const [])
            .map((e) => WallOfFameEntryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    // API endpoint format: each item is a champion for that level
    return WallOfFameLevelModel(
      level: json['level'] as String? ?? '',
      champion: WallOfFameEntryModel.fromJson(json),
      runnersUp: const [],
    );
  }
}
