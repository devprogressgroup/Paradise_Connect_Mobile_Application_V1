class LandingPageUrlModel {
  final String landingPageUrl;

  LandingPageUrlModel({required this.landingPageUrl});

  factory LandingPageUrlModel.fromJson(Map<String, dynamic> json) {
    return LandingPageUrlModel(
      landingPageUrl: json['landing_page_url'] as String,
    );
  }
}
