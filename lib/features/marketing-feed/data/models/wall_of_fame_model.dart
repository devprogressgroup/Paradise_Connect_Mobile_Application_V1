import 'package:progress_group/features/marketing-feed/domain/entities/wall_of_fame_entity.dart';

class WallOfFameEntryModel extends WallOfFameEntryEntity {
  const WallOfFameEntryModel({
    required super.name,
    super.info,
    super.highlight,
    super.photoUrl,
  });

  factory WallOfFameEntryModel.fromJson(Map<String, dynamic> json) {
    return WallOfFameEntryModel(
      name: json['name'] as String? ?? '-',
      info: json['info'] as String?,
      highlight: json['highlight'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class WallOfFameLevelModel extends WallOfFameLevelEntity {
  const WallOfFameLevelModel({
    required super.level,
    required super.champion,
    super.runnersUp,
  });

  factory WallOfFameLevelModel.fromJson(Map<String, dynamic> json) {
    return WallOfFameLevelModel(
      level: json['level'] as String? ?? '',
      champion: WallOfFameEntryModel.fromJson(json['champion'] as Map<String, dynamic>? ?? const {}),
      runnersUp: (json['runners_up'] as List<dynamic>? ?? const [])
          .map((e) => WallOfFameEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
