import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

class WallOfFameEntryEntity extends Equatable {
  final int? id;
  final String name;
  final String? initials;

  /// Jabatan/project, mis. "SE PAR1".
  final String? info;
  final String? highlight;
  final String? photoUrl;
  final FeedMediaEntity? media;

  const WallOfFameEntryEntity({
    this.id,
    required this.name,
    this.initials,
    this.info,
    this.highlight,
    this.photoUrl,
    this.media,
  });

  @override
  List<Object?> get props => [id, name, initials, info, highlight, photoUrl, media];
}

/// Satu level Wall of Fame (TOP GM/SM/SPV/SE): juara #1 + peringkat berikutnya.
class WallOfFameLevelEntity extends Equatable {
  final String level;
  final WallOfFameEntryEntity champion;
  final List<WallOfFameEntryEntity> runnersUp;

  const WallOfFameLevelEntity({
    required this.level,
    required this.champion,
    this.runnersUp = const [],
  });

  @override
  List<Object?> get props => [level, champion, runnersUp];
}
