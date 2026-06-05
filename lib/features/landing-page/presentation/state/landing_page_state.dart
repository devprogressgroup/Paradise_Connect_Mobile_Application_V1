abstract class LandingPageState {}

class LandingPageInitial extends LandingPageState {}

class LandingPageLoading extends LandingPageState {}

class LandingPageLoaded extends LandingPageState {
  final String url;
  LandingPageLoaded(this.url);
}

class LandingPageError extends LandingPageState {
  final String message;
  LandingPageError(this.message);
}
