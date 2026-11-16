class ProjectSite {
  final String groupName;
  final String unitName;
  final String url;

  /// Id dari `GET /property/siteplan-settings` (cluster: `township_id`, `id` = siteplan_id,
  /// `company_id`) — dipakai cari township unit yang diklik di peta (mis. untuk
  /// `GET /property/virtual-account`), karena relay pin dari WebView tidak membawa township_id.
  final int? townshipId;
  final int? siteplanId;
  final int? companyId;

  ProjectSite({
    required this.groupName,
    required this.unitName,
    required this.url,
    this.townshipId,
    this.siteplanId,
    this.companyId,
  });
}
