import 'package:progress_group/features/app-menu/domain/entities/app_menu_entity.dart';

class AppMenuState {
  /// Null sampai server pernah memberi menu. Tanpa menu, sidebar tidak menampilkan Home maupun daftar modul.
  final AppMenuEntity? menu;
  final bool isLoading;

  const AppMenuState({this.menu, this.isLoading = false});

  AppMenuState copyWith({AppMenuEntity? menu, bool? isLoading}) {
    return AppMenuState(
      menu: menu ?? this.menu,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
