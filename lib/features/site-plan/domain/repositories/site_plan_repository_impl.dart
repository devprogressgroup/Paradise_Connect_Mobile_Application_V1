import '../../data/datasources/siteplan_remote_datasource.dart';
import '../entities/project_site.dart';
import 'site_plan_repository.dart';

class SitePlanRepositoryImpl implements SitePlanRepository {
  final SiteplanRemoteDataSource dataSource;

  SitePlanRepositoryImpl(this.dataSource);

  static const String _baseUrl =
      'http://dynamics.paradise.id/paradise_api/siteplan_mobile';
  static const Map<String, String> _webviewHeaders = {
    'X-App-Token': 'd9f82b7a4c6e11ec94660242ac120002XSitePlan',
  };

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
          sites.add(ProjectSite(
            groupName: cluster['township_name'] as String? ??township['township_name'] as String? ??'',
            unitName: cluster['siteplan_name'] as String? ?? '',
            url: '$_baseUrl?pdkey=hoaxprogress&company_id=$companyId&siteplan_id=$siteplanId',
            headers: _webviewHeaders,
          ));
        }
      }
    }

    return sites;
  }
}
