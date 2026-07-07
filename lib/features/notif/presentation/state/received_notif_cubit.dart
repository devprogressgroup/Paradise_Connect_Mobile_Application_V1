import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/received_notif_entity.dart';
import '../../../../core/utils/helpers/app_time.dart';

class ReceivedNotifState {
  final List<ReceivedNotifEntity> items;
  const ReceivedNotifState(this.items);
}

class ReceivedNotifCubit extends Cubit<ReceivedNotifState> {
  static ReceivedNotifCubit? _instance;
  static const _prefsKey = 'received_notifs_v1';
  static const _maxItems = 50;

  ReceivedNotifCubit() : super(const ReceivedNotifState([])) {
    _instance = this;
    _load();
  }

  /// Dipanggil dari PushNotificationService saat notif masuk — tidak perlu context.
  static void receive({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic> data = const {},
  }) {
    if (_instance == null || _instance!.isClosed) return;
    _instance!._insert(ReceivedNotifEntity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      data: Map<String, dynamic>.from(data),
      receivedAt: AppTime.now(),
    ));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? [];
      final items = raw.map((s) {
        try {
          return ReceivedNotifEntity.fromJson(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<ReceivedNotifEntity>().toList();
      if (!isClosed) emit(ReceivedNotifState(items));
    } catch (_) {}
  }

  void _insert(ReceivedNotifEntity item) {
    final updated = [item, ...state.items].take(_maxItems).toList();
    emit(ReceivedNotifState(updated));
    _save(updated);
  }

  void clear() {
    emit(const ReceivedNotifState([]));
    _save([]);
  }

  Future<void> _save(List<ReceivedNotifEntity> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKey,
        items.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (_) {}
  }
}
