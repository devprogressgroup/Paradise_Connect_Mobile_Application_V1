import '../entities/project_site.dart';
// Jika file interface repository-mu ada di folder domain, import di sini:
// import '../../domain/repositories/site_plan_repository.dart';

class SitePlanRepositoryImpl {
  /// Fungsi untuk mengambil daftar denah proyek.
  /// Di masa depan, fungsi ini bisa diubah menjadi asinkron (Future) 
  /// jika kamu ingin mengambil data dari API (Dio/Http).
  List<ProjectSite> getAvailableSites() {
    return [
      // --- Paradise Serpong City (Group 1) ---
      ProjectSite(
        groupName: 'Paradise Serpong City',
        unitName: 'Vista',
        url: 'https://connect.paradise.id/', // Ganti dengan URL asli
      ),
      ProjectSite(
        groupName: 'Paradise Serpong City',
        unitName: 'Voyage',
        url: 'https://connect.paradise.id/', // Ganti dengan URL asli
      ),

      // --- Paradise Serpong City 2 (Group 2) ---
      ProjectSite(
        groupName: 'Paradise Serpong City 2',
        unitName: 'Ecoscape',
        url: 'https://paradise.co.id/id/paradise-serpong-city-2', // Ganti dengan URL asli
      ),
      ProjectSite(
        groupName: 'Paradise Serpong City 2',
        unitName: 'Ecoardence',
        url: 'https://paradise.co.id/id/paradise-serpong-city-2', // Ganti dengan URL asli
      ),
      
      // Tambahkan unit lain di sini...
    ];
  }
}