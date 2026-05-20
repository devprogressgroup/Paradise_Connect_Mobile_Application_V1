import '../entities/project_site.dart';

abstract class SitePlanRepository {
  Future<List<ProjectSite>> getAvailableSites();
}