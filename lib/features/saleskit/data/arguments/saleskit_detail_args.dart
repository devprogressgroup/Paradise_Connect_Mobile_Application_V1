class SalesKitDetailArgs {
  final String? title;
  final int page;
  final int? townshipId;
  final String? townshipSlug;
  final String? brochure;
  final String? productKnowledge;
  final String? priceList;
  final String? other;

  SalesKitDetailArgs({
    this.title,
    this.page = 0, // 0: project list, 1: detail (clusters/commercials), 2: share
    this.townshipId,
    this.townshipSlug,
    this.brochure,
    this.productKnowledge,
    this.priceList,
    this.other,
  });
}
