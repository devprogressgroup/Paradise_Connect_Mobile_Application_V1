import '../entities/project_site.dart';

class SitePlanRepositoryImpl {
  List<ProjectSite> getAvailableSites() {
    return [
      ProjectSite(
        groupName: 'Paradise Serpong City',
        unitName: 'Vista',
        url: 'http://dynamics.paradise.id/paradise_api/siteplan_mobile?pdkey=hoaxprogress&company_id=5&siteplan_id=21',
        headers: {'X-App-Token': 'd9f82b7a4c6e11ec94660242ac120002XSitePlan'},
      ),
      ProjectSite(
        groupName: 'Paradise Serpong City',
        unitName: 'Voyage',
        url: 'https://connect.paradise.id/',
      ),
      ProjectSite(
        groupName: 'Paradise Serpong City 2',
        unitName: 'Ecoscape',
        url: 'https://drive.google.com/file/d/1uoo5sk90v3VxVtPp7k6wdX9x-pe4UDW8/view',
      ),
      ProjectSite(
        groupName: 'Paradise Serpong City 2',
        unitName: 'Ecoardence',
        url: 'https://paradise.co.id/id/paradise-serpong-city-2',
      ),
    ];
  }
}
