import '../../domain/entities/cluster_entity.dart';

class ClusterModel extends ClusterEntity {
  const ClusterModel({
    required super.id,
    required super.slug,
    required super.name,
    required super.logoMobile,
    required super.townshipId,
    super.brochure,
    super.productKnowledge,
    super.priceList,
    super.other,
    super.showOnMobile,
  });

  factory ClusterModel.fromJson(Map<String, dynamic> json) {
    return ClusterModel(
      id: json['id'] as int,
      slug: json['slug'] as String,
      name: json['name'] as String,
      logoMobile: json['logo_mobile'] as String? ?? '',
      townshipId: json['township_id'] as int,
      brochure: json['brochure'] as String?,
      productKnowledge: json['product_knowledge'] as String?,
      priceList: json['price_list'] as String?,
      other: json['other'] as String?,
      showOnMobile: json['show_on_mobile'] is int ? json['show_on_mobile'] as int : 0,
    );
  }
}
