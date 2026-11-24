import 'package:progress_group/features/app-menu/domain/entities/app_menu_entity.dart';

class AppMenuItemModel extends AppMenuItemEntity {
  const AppMenuItemModel({
    required super.code,
    required super.label,
    required super.icon,
    required super.route,
    required super.isHome,
  });

  factory AppMenuItemModel.fromJson(Map<String, dynamic> json) {
    return AppMenuItemModel(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
      isHome: json['is_home'] == true,
    );
  }
}

class AppMenuModel extends AppMenuEntity {
  const AppMenuModel({required super.home, required super.modules});

  factory AppMenuModel.fromJson(Map<String, dynamic> json) {
    final rawModules = json['modules'];
    final modules = rawModules is List
        ? rawModules
              .whereType<Map>()
              .map((m) => AppMenuItemModel.fromJson(Map<String, dynamic>.from(m)))
              .toList()
        : <AppMenuItemModel>[];
    return AppMenuModel(
      home: json['home']?.toString() ?? '',
      modules: modules,
    );
  }
}
