import 'package:equatable/equatable.dart';

/// Penulis post/komentar di Marketing Feed — sales (lewat "Bagikan Momen") atau akun moderator
/// Tim Marketing.
class FeedAuthorEntity extends Equatable {
  final int id;
  final String name;
  final String? subtitle;
  final String? photoUrl;
  final bool isModerator;

  const FeedAuthorEntity({
    required this.id,
    required this.name,
    this.subtitle,
    this.photoUrl,
    this.isModerator = false,
  });

  @override
  List<Object?> get props => [id, name, subtitle, photoUrl, isModerator];
}
