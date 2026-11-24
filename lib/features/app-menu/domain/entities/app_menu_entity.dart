/// Satu modul di sidebar, urutannya sudah ditentukan server (sort_order).
class AppMenuItemEntity {
  final String code;
  final String label;
  final String icon;
  final String route;
  final bool isHome;

  const AppMenuItemEntity({
    required this.code,
    required this.label,
    required this.icon,
    required this.route,
    required this.isHome,
  });
}

/// Menu sidebar dari server: modul mana yang boleh dilihat user + modul Home.
class AppMenuEntity {
  final String home;
  final List<AppMenuItemEntity> modules;

  const AppMenuEntity({required this.home, required this.modules});

  /// Modul yang dibuka slot Home (`is_home: true`), null kalau server tidak mengirim.
  AppMenuItemEntity? get homeModule {
    for (final m in modules) {
      if (m.isHome) return m;
    }
    return null;
  }
}
