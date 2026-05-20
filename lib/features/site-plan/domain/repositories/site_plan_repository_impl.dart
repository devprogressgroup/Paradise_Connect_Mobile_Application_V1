import '../entities/project_site.dart';
import '../../data/datasources/siteplan_remote_datasource.dart';
import 'site_plan_repository.dart';

class SitePlanRepositoryImpl implements SitePlanRepository {
  final SiteplanRemoteDataSource remoteDataSource;
  SitePlanRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ProjectSite>> getAvailableSites() async {
    final data = await remoteDataSource.getSiteplanSettings();

    // 'meta' di-skip, hanya ambil 'townships'
    final townships = data['townships'] as List<dynamic>? ?? [];
    final sites = <ProjectSite>[];

    for (final township in townships) {
      final townshipName = township['township_name'] as String? ?? '';

      final clusters = township['clusters'] as List<dynamic>? ?? [];
      for (final c in clusters) {
        if (c['show_on_mobile'] == 1) {
          sites.add(ProjectSite(
            groupName: townshipName,
            unitName: c['siteplan_name'] as String? ?? '',
            url: c['link_siteplan'] as String? ?? '',
          ));
        }
      }

      final commercials = township['commercials'] as List<dynamic>? ?? [];
      for (final c in commercials) {
        if (c['show_on_mobile'] == 1) {
          sites.add(ProjectSite(
            groupName: townshipName,
            unitName: c['siteplan_name'] as String? ?? '',
            url: c['link_siteplan'] as String? ?? '',
          ));
        }
      }
    }

    return sites;
  }
}
