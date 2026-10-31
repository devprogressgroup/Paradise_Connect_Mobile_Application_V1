import 'package:equatable/equatable.dart';

/// Penulis post/komentar di Marketing Feed — sales (lewat "Bagikan Momen") atau akun moderator
/// Tim Marketing.
class FeedAuthorEntity extends Equatable {
  final int id;
  final String name;
  final String initials;
  final String? badge;
  final String? subtitle;
  final String? photoUrl;
  final bool isOfficial;

  const FeedAuthorEntity({
    this.id = 0,
    required this.name,
    this.initials = '',
    this.badge,
    this.subtitle,
    this.photoUrl,
    this.isOfficial = false,
  });

  bool get isModerator => isOfficial || (badge?.toLowerCase().contains('moderator') ?? false);

  @override
  List<Object?> get props => [id, name, initials, badge, subtitle, photoUrl, isOfficial];
}
