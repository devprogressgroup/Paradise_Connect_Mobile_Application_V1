class ProjectSite {
  final String groupName;
  final String unitName;
  final String url;
  final Map<String, String> headers;

  ProjectSite({
    required this.groupName,
    required this.unitName,
    required this.url,
    this.headers = const {},
  });
}