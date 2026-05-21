import '../entities/project_site.dart';

abstract class SitePlanRepository {
  List<ProjectSite> getAvailableSites();
}