import '../../domain/entities/cluster_entity.dart';

class ClusterModel extends ClusterEntity {
  const ClusterModel({
    required super.id,
    required super.slug,
    required super.name,
    required super.logo,
    required super.townshipId,
    super.brochure,
    super.productKnowledge,
    super.priceList,
  });

  factory ClusterModel.fromJson(Map<String, dynamic> json) {
    return ClusterModel(
      id: json['id'] as int,
      slug: json['slug'] as String,
      name: json['name'] as String,
      logo: json['logo'] as String? ?? '',
      townshipId: json['township_id'] as int,
      brochure: json['brochure'] as String?,
      productKnowledge: json['product_knowledge'] as String?,
      priceList: json['price_list'] as String?,
    );
  }
}
