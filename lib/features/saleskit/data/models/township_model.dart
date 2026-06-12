import '../../domain/entities/township_entity.dart';

class TownshipModel extends TownshipEntity {
  const TownshipModel({
    required super.id,
    required super.slug,
    required super.name,
    required super.logo,
    required super.groupBanner,
    required super.location,
  });

  factory TownshipModel.fromJson(Map<String, dynamic> json) {
    return TownshipModel(
      id: json['id'] as int,
      slug: json['slug'] as String,
      name: json['name'] as String,
      logo: json['logo_full_color'] as String? ?? '',
      groupBanner: json['group_banner'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }
}
