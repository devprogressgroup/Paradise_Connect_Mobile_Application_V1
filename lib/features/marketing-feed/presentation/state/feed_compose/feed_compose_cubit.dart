import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/save_feed_post_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/share_feed_moment_usecase.dart';
import 'feed_compose_state.dart';

/// Submit form "Bagikan Momen" (sales), "Post Baru" & "Poll Baru" (moderator).
class FeedComposeCubit extends Cubit<FeedComposeState> {
  final ShareFeedMomentUseCase shareFeedMomentUseCase;
  final SaveFeedPostUseCase saveFeedPostUseCase;

  FeedComposeCubit({
    required this.shareFeedMomentUseCase,
    required this.saveFeedPostUseCase,
  }) : super(const FeedComposeInitial());

  Future<void> shareMoment(ShareFeedMomentParams params) async {
    emit(const FeedComposeSubmitting());
    final result = await shareFeedMomentUseCase(params);
    result.fold(
      (message) => emit(FeedComposeError(message)),
      (post) => emit(FeedComposeSuccess(post)),
    );
  }

  Future<void> savePost(SaveFeedPostParams params) async {
    emit(const FeedComposeSubmitting());
    final result = await saveFeedPostUseCase(params);
    result.fold(
      (message) => emit(FeedComposeError(message)),
      (post) => emit(FeedComposeSuccess(post)),
    );
  }

  void reset() => emit(const FeedComposeInitial());
}
