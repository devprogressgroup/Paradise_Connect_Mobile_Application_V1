import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

enum FeedCalendarStatus { initial, loading, loaded, error }

/// State Kalender Jadwal (moderator). [items] = kiriman terjadwal & tayang pada rentang terakhir yang dimuat.
class FeedCalendarState {
  final FeedCalendarStatus status;
  final List<FeedPostEntity> items;
  final String? errorMessage;

  const FeedCalendarState({
    this.status = FeedCalendarStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  FeedCalendarState copyWith({
    FeedCalendarStatus? status,
    List<FeedPostEntity>? items,
    String? errorMessage,
  }) {
    return FeedCalendarState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}
