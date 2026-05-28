import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:progress_group/core/network/api_constants.dart';

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
    debugPrint('SITE PLAN response: ${jsonEncode(data)}');
    final List<ProjectSite> sites = [];
    final townships = data['townships'] as List<dynamic>? ?? [];

    for (final township in townships) {
      final clusters = township['clusters'] as List<dynamic>? ?? [];
      for (final cluster in clusters) {
        if (cluster['show_on_mobile'] == 1) {
          final companyId = cluster['company_id']?.toString() ?? '';
          final siteplanId = cluster['id']?.toString() ?? '';

          // Suffix query untuk site plan
          const query = 'pdkey=hoaxprogress';

          String url;
          Map<String, String> headers;

          if (kIsWeb) {
            // Web: route melalui backend proxy Laravel (server-to-server, tidak ada CORS).
            // Service Worker tidak bisa bypass CORS untuk custom header X-App-Token.
            final backendBase = ApiConstants.baseUrl; // http://host:8000/api
            url     = '$backendBase/property/siteplan-proxy?$query&company_id=$companyId&siteplan_id=$siteplanId';
            headers = const {};
          } else {
            // Mobile: URL asli, token dikirim via dart:io local proxy
            url     = '$_baseUrl?$query&company_id=$companyId&siteplan_id=$siteplanId';
            headers = _webviewHeaders;
          }

          debugPrint('SITE PLAN [SitePlan] URL: $url');
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
