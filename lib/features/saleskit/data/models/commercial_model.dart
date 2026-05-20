import '../../domain/entities/commercial_entity.dart';

class CommercialModel extends CommercialEntity {
  const CommercialModel({
    required super.id,
    required super.slug,
    required super.name,
    required super.logo,
    required super.townshipId,
    super.brochure,
    super.productKnowledge,
    super.priceList,
  });

  factory CommercialModel.fromJson(Map<String, dynamic> json) {
    return CommercialModel(
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
