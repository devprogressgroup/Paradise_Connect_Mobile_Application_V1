class ClusterEntity {
  final int id;
  final String slug;
  final String name;
  final String logoMobile;
  final int townshipId;
  final String? brochure;
  final String? productKnowledge;
  final String? priceList;
  final String? other;
  final int showOnMobile;

  const ClusterEntity({
    required this.id,
    required this.slug,
    required this.name,
    required this.logoMobile,
    required this.townshipId,
    this.brochure,
    this.productKnowledge,
    this.priceList,
    this.other,
    this.showOnMobile = 0,
  });
}
