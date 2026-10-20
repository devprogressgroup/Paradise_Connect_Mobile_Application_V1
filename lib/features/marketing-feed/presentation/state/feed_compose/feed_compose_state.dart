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
  const FeedComposeSubmitting();
}

class FeedComposeSuccess extends FeedComposeState {
  final FeedPostEntity post;

  const FeedComposeSuccess(this.post);

  @override
  List<Object?> get props => [post];
}

class FeedComposeError extends FeedComposeState {
  final String message;

  const FeedComposeError(this.message);

  @override
  List<Object?> get props => [message];
}
