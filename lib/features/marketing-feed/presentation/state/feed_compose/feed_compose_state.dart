import 'package:equatable/equatable.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

abstract class FeedComposeState extends Equatable {
  const FeedComposeState();

  @override
  List<Object?> get props => [];
}

class FeedComposeInitial extends FeedComposeState {
  const FeedComposeInitial();
}

class FeedComposeSubmitting extends FeedComposeState {
  /// 0..1 selama upload multipart; null = belum/tidak diketahui.
  final double? progress;

  const FeedComposeSubmitting({this.progress});

  @override
  List<Object?> get props => [progress];
}

class FeedComposeSuccess extends FeedComposeState {
  final FeedPostEntity post;

  const FeedComposeSuccess(this.post);

  @override
  List<Object?> get props => [post];
}

class FeedComposeError extends FeedComposeState {
  final String message;
  final String? errorCode;
  final String? raptor;
  final String? hint;

  const FeedComposeError(
    this.message, {
    this.errorCode,
    this.raptor,
    this.hint,
  });

  bool get isStorageError => errorCode == 'STORAGE_ERROR' || raptor != null;

  @override
  List<Object?> get props => [message, errorCode, raptor, hint];
}
