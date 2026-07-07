import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:progress_group/core/network/api_constants.dart';

import '../../data/datasources/siteplan_remote_datasource.dart';
import '../entities/project_site.dart';
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

          
          const query = 'pdkey=hoaxprogress';

          String url;
          Map<String, String> headers;

          if (kIsWeb) {
            
            
            final backendBase = ApiConstants.baseUrl; 
            url     = '$backendBase/property/siteplan-proxy?$query&company_id=$companyId&siteplan_id=$siteplanId';
            headers = const {};
          } else {
            
            url     = '${ApiConstants.siteplanBaseUrl}?$query&company_id=$companyId&siteplan_id=$siteplanId';
            headers = ApiConstants.siteplanWebviewHeaders;
          }

          sites.add(
            ProjectSite(
              groupName:
                  cluster['township_name'] as String? ??
                  township['township_name'] as String? ??
                  '',
              unitName: cluster['siteplan_name'] as String? ?? '',
              url: url,
              headers: headers,
            ),
          );
        }
      }
    }

    return sites;
  }
}
