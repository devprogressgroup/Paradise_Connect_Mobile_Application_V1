import 'package:progress_group/core/network/api_constants.dart';

import '../../data/datasources/siteplan_remote_datasource.dart';
import '../entities/project_site.dart';
import '../entities/unit_detail.dart';
import 'site_plan_repository.dart';

class SitePlanRepositoryImpl implements SitePlanRepository {
  final SiteplanRemoteDataSource dataSource;

  SitePlanRepositoryImpl(this.dataSource);

  @override
  Future<List<ProjectSite>> getAvailableSites() async {
    final data = await dataSource.getSiteplanSettings();
    final List<ProjectSite> sites = [];
    final townships = data['townships'] as List<dynamic>? ?? [];

    for (final township in townships) {
      final clusters = township['clusters'] as List<dynamic>? ?? [];
      for (final cluster in clusters) {
        if (cluster['show_on_mobile'] == 1) {
          final companyId = cluster['company_id']?.toString() ?? '';
          final siteplanId = cluster['id']?.toString() ?? '';


          // Selalu lewat proxy Laravel (/property/siteplan-proxy) — SAMA untuk web maupun
          // mobile. Backend yang menyisipkan header X-App-Token DAN query param pdkey ke
          // server siteplan asli (lihat PropertyController::forwardToSiteplan()), jadi app
          // TIDAK PERNAH connect langsung ke server siteplan atau tahu credential apa pun.
          final backendBase = ApiConstants.baseUrl;
          final url = '$backendBase/property/siteplan-proxy?company_id=$companyId&siteplan_id=$siteplanId';

          sites.add(
            ProjectSite(
              groupName:
                  cluster['township_name'] as String? ??
                  township['township_name'] as String? ??
                  '',
              unitName: cluster['siteplan_name'] as String? ?? '',
              url: url,
            ),
          );
        }
      }
    }

    return sites;
  }

  @override
  Future<UnitDetail> getUnitDetail({
    required int siteplanId,
    required int companyId,
    required int productId,
    required int propertyId,
  }) async {
    final data = await dataSource.getPropertyPricing(
      siteplanId: siteplanId,
      companyId: companyId,
      productId: productId,
      propertyId: propertyId,
    );
    return UnitDetail.fromJson(data);
  }
}
