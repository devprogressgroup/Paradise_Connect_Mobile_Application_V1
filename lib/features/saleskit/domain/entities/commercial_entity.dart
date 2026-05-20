class CommercialEntity {
  final int id;
  final String slug;
  final String name;
  final String logo;
  final int townshipId;
  final String? brochure;
  final String? productKnowledge;
  final String? priceList;

  const CommercialEntity({
    required this.id,
    required this.slug,
    required this.name,
    required this.logo,
    required this.townshipId,
    this.brochure,
    this.productKnowledge,
    this.priceList,
  });
}
