import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

enum FeedDraftsStatus { initial, loading, loaded, error }

class FeedDraftsState extends Equatable {
  final FeedDraftsStatus status;
  final List<FeedPostEntity> items;
  final String? errorMessage;

  const FeedDraftsState({
    this.status = FeedDraftsStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  FeedDraftsState copyWith({
    FeedDraftsStatus? status,
    List<FeedPostEntity>? items,
    String? errorMessage,
  }) {
    return FeedDraftsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
