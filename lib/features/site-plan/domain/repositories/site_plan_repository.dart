import '../entities/project_site.dart';
import '../entities/unit_detail.dart';

abstract class SitePlanRepository {
  Future<List<ProjectSite>> getAvailableSites();

  Future<UnitDetail> getUnitDetail({
    required int siteplanId,
    required int companyId,
    required int productId,
    required int propertyId,
  });
}