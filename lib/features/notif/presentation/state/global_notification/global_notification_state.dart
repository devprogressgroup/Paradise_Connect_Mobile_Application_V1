import 'package:equatable/equatable.dart';
import 'package:progress_group/features/notif/data/models/global_notification_model.dart';

enum GlobalNotificationStatus { initial, loading, loaded, error }

class GlobalNotificationState extends Equatable {
  final GlobalNotificationStatus status;
  final List<GlobalNotificationEntity> items;
  final String? error;

  const GlobalNotificationState({
    this.status = GlobalNotificationStatus.initial,
    this.items = const [],
    this.error,
  });

  GlobalNotificationState copyWith({
    GlobalNotificationStatus? status,
    List<GlobalNotificationEntity>? items,
    String? error,
  }) {
    return GlobalNotificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}
