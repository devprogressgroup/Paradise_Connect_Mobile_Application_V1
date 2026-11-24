import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/assets.dart';

/// Kode modul dari server → path GoRouter. Kode yang belum ada di sini tampil tanpa aksi.
const Map<String, String> appMenuRouteByCode = {
  'REPORT': '/report',
  'MARKETING_FEED': '/',
  'FEEDS': '/marketing-feed/my-submissions',
  'CONTACTS': '/contact',
  'INBOX': '/inbox',
  'SITE_PLAN': '/site-plan',
  'SALES_KIT': '/sales-kit',
  'SIAP_HUNI': '/siap-huni',
  'ATTENDANCE': '/attandance',
  'RESERVE_ORDER': '/reserve-order',
};

/// Kode modul → index item sidebar (dipakai untuk indikator halaman aktif).
const Map<String, int> appMenuIndexByCode = {
  'MARKETING_FEED': 0,
  'CONTACTS': 1,
  'INBOX': 2,
  'SITE_PLAN': 4,
  'SALES_KIT': 5,
  'ATTENDANCE': 6,
  'SIAP_HUNI': 9,
  'RESERVE_ORDER': 10,
  'REPORT': 11,
  'FEEDS': 12,
};

/// Index slot Home (sama dengan Marketing Feed di bottom nav).
const int appMenuHomeIndex = 0;

const int _noIndex = -1;

String? appMenuPathFor(String code) => appMenuRouteByCode[code];

int appMenuIndexFor(String code) => appMenuIndexByCode[code] ?? _noIndex;

class AppMenuIconSpec {
  /// Path asset PNG, dipakai kalau tidak null.
  final String? asset;
  final IconData? iconData;

  const AppMenuIconSpec({this.asset, this.iconData});
}

/// Nama ikon dari server → ikon yang sudah dipakai di sidebar.
AppMenuIconSpec appMenuIconFor(String icon) {
  switch (icon) {
    case 'dashboard':
      return const AppMenuIconSpec(asset: icSidebarDashboard);
    case 'megaphone':
      return const AppMenuIconSpec(iconData: Icons.campaign_outlined);
    case 'post':
      return const AppMenuIconSpec(iconData: Icons.history_rounded);
    case 'contact':
      return const AppMenuIconSpec(asset: icSidebarContacts);
    case 'inbox':
      return const AppMenuIconSpec(asset: icSidebarInbox);
    case 'siteplan':
      return const AppMenuIconSpec(asset: icSidebarSitePlan);
    case 'saleskit':
      return const AppMenuIconSpec(asset: icSidebarSalesKit);
    case 'homeR':
      return const AppMenuIconSpec(iconData: Icons.home_rounded);
    case 'attendance':
      return const AppMenuIconSpec(asset: icNavAttendance);
    case 'offer':
      return const AppMenuIconSpec(iconData: Icons.local_offer);
    default:
      return const AppMenuIconSpec(iconData: Icons.apps_rounded);
  }
}
