import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/network/marketing_feed_exception.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/save_feed_post_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/share_feed_moment_usecase.dart';
import 'feed_compose_state.dart';

/// Submit form "Bagikan Momen" (sales) dan form Post / Poll / Link (moderator).
class FeedComposeCubit extends Cubit<FeedComposeState> {
  final ShareFeedMomentUseCase shareFeedMomentUseCase;
  final SaveFeedPostUseCase saveFeedPostUseCase;

  FeedComposeCubit({
    required this.shareFeedMomentUseCase,
    required this.saveFeedPostUseCase,
  }) : super(const FeedComposeInitial());

  Future<void> shareMoment(ShareFeedMomentParams params) =>
      _submit((onProgress) => shareFeedMomentUseCase(params.copyWith(onProgress: onProgress)));

  Future<void> savePost(SaveFeedPostParams params) =>
      _submit((onProgress) => saveFeedPostUseCase(params.copyWith(onProgress: onProgress)));

  Future<void> _submit(
    Future<Either<MarketingFeedException, FeedPostEntity>> Function(void Function(int sent, int total) onProgress) call,
  ) async {
    emit(const FeedComposeSubmitting(progress: 0));
    var lastPercent = 0;
    final result = await call((sent, total) {
      if (total <= 0 || isClosed) return;
      // Cukup emit tiap naik 1% — callback Dio dipanggil per chunk.
      final percent = sent * 100 ~/ total;
      if (percent == lastPercent) return;
      lastPercent = percent;
      emit(FeedComposeSubmitting(progress: percent / 100));
    });
    if (isClosed) return;
    result.fold(
      (e) => emit(FeedComposeError(
        e.message,
        errorCode: e.errorCode,
        raptor: e.raptor,
        hint: e.hint,
      )),
      (post) => emit(FeedComposeSuccess(post)),
    );
  }

  void reset() => emit(const FeedComposeInitial());
}
