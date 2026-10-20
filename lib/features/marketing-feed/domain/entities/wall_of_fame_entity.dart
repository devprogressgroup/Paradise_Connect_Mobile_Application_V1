import 'package:equatable/equatable.dart';

class WallOfFameEntryEntity extends Equatable {
  final String name;

  /// Jabatan/project, mis. "GM PAR1 & PAR2".
  final String? info;
  final String? highlight;
  final String? photoUrl;

  const WallOfFameEntryEntity({
    required this.name,
    this.info,
    this.highlight,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [name, info, highlight, photoUrl];
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
