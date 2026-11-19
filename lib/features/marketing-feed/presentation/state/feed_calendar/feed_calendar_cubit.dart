import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_feed_calendar_usecase.dart';
import 'feed_calendar_state.dart';

/// State halaman "Kalender Jadwal" (moderator).
class FeedCalendarCubit extends Cubit<FeedCalendarState> {
  final GetFeedCalendarUseCase getFeedCalendarUseCase;

  FeedCalendarCubit({required this.getFeedCalendarUseCase})
    : super(const FeedCalendarState());

  /// Memuat kiriman pada rentang tanggal [from]..[to] (inklusif). Item rentang sebelumnya diganti.
  Future<void> fetch({required DateTime from, required DateTime to}) async {
    emit(state.copyWith(status: FeedCalendarStatus.loading));
    final result = await getFeedCalendarUseCase(from: from, to: to);
    if (isClosed) return;
    result.fold(
      (message) => emit(
        state.copyWith(status: FeedCalendarStatus.error, errorMessage: message),
      ),
      (items) => emit(
        FeedCalendarState(status: FeedCalendarStatus.loaded, items: items),
      ),
    );
  }
}
