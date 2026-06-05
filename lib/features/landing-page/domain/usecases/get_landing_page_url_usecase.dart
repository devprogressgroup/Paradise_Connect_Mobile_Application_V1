import '../repositories/landing_page_repository.dart';

class GetLandingPageUrlUseCase {
  final LandingPageRepository repository;

  GetLandingPageUrlUseCase(this.repository);

  Future<String> call() => repository.getLandingPageUrl();
}
