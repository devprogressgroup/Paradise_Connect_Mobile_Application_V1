import 'package:dartz/dartz.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Moderator: kiriman terjadwal & tayang pada rentang tanggal [from]..[to] (Kalender Jadwal).
class GetFeedCalendarUseCase {
  final MarketingFeedRepository repository;

  GetFeedCalendarUseCase(this.repository);

  Future<Either<String, List<FeedPostEntity>>> call({
    required DateTime from,
    required DateTime to,
  }) async {
    return await repository.getModeratorCalendar(from: from, to: to);
  }
}
