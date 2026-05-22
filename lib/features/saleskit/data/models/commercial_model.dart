import '../../domain/entities/commercial_entity.dart';

class CommercialModel extends CommercialEntity {
  const CommercialModel({
    required super.id,
    required super.slug,
    required super.name,
    required super.logoMobile,
    required super.townshipId,
    super.brochure,
    super.productKnowledge,
    super.priceList,
    super.showOnMobile,
  });

  factory CommercialModel.fromJson(Map<String, dynamic> json) {
    return CommercialModel(
      id: json['id'] as int,
      slug: json['slug'] as String,
      name: json['name'] as String,
      logoMobile: json['logo_mobile'] as String? ?? '',
      townshipId: json['township_id'] as int,
      brochure: json['brochure'] as String?,
      productKnowledge: json['product_knowledge'] as String?,
      priceList: json['price_list'] as String?,
      showOnMobile: json['show_on_mobile'] is int ? json['show_on_mobile'] as int : 1,
    );
  }
}
