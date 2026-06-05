import '../../domain/repositories/landing_page_repository.dart';
import '../datasources/landing_page_remote_datasource.dart';

class LandingPageRepositoryImpl implements LandingPageRepository {
  final LandingPageRemoteDataSource remoteDataSource;

  LandingPageRepositoryImpl(this.remoteDataSource);

  @override
  Future<String> getLandingPageUrl() async {
    final model = await remoteDataSource.getLandingPageUrl();
    return model.landingPageUrl;
  }
}
