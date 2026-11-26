import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_my_profile_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/react_feed_post_usecase.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/vote_feed_poll_usecase.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_live/feed_live_stats.dart';

enum MyProfileStatus { initial, loading, loaded, error }

/// Tab profil. [api] dikirim ke server sebagai query `tab`.
enum ProfileTab {
  semua('Semua', 'semua'),
  tautan('Tautan', 'tautan'),
  reels('Foto & Video', 'reels');

  final String label;
  final String api;
  const ProfileTab(this.label, this.api);
}

class MyProfileState {
  final MyProfileStatus status;

  /// Identitas dan statistik profil (diambil dari respons terakhir).
  final MyProfileEntity? profile;
  final ProfileTab tab;

  /// Kartu dari semua halaman yang sudah dimuat untuk [tab] ini.
  final List<FeedPostEntity> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final String? errorMessage;

  const MyProfileState({
    this.status = MyProfileStatus.initial,
    this.profile,
    this.tab = ProfileTab.semua,
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.errorMessage,
  });
}

/// State halaman profil Marketing Feed (punya sendiri atau user lain), dengan pagination per tab.
class MyProfileCubit extends Cubit<MyProfileState> {
  final GetMyProfileUseCase getMyProfileUseCase;
  final ReactFeedPostUseCase reactFeedPostUseCase;
  final VoteFeedPollUseCase voteFeedPollUseCase;

  static const int _perPage = 10;

  int? _userId;

  /// Nomor permintaan terakhir. Respons dari permintaan yang sudah basi (ganti tab / refresh) dibuang.
  int _seq = 0;

  MyProfileCubit({
    required this.getMyProfileUseCase,
    required this.reactFeedPostUseCase,
    required this.voteFeedPollUseCase,
  }) : super(const MyProfileState());

  /// Like/dislike di profil: optimistic, lalu disinkronkan dengan server atau di-rollback. Balikan: pesan error atau null.
  Future<String?> react(int postId, FeedReaction tapped) async {
    final before = _findItem(postId);
    if (before == null) return null;

    final next = before.myReaction == tapped ? FeedReaction.none : tapped;

    int count(int current, FeedReaction type) =>
        current - (before.myReaction == type ? 1 : 0) + (next == type ? 1 : 0);

    _replaceItem(
      before.copyWith(
        myReaction: next,
        likeCount: count(before.likeCount, FeedReaction.like),
        dislikeCount: count(before.dislikeCount, FeedReaction.dislike),
      ),
    );
    FeedLiveStats.instance.markLocalChange(postId);

    final result = await reactFeedPostUseCase(postId, next);
    return result.fold(
      (message) {
        _replaceItem(before);
        return message;
      },
      (res) {
        _replaceItem(
          before.copyWith(
            myReaction: res.myReaction,
            likeCount: res.likes,
            dislikeCount: res.dislikes,
          ),
        );
        FeedLiveStats.instance.markLocalChange(postId);
        return null;
      },
    );
  }

  /// Kirim jawaban poll dari profil. Balikan: pesan error, atau null kalau sukses.
  Future<String?> vote(int postId, List<int> optionIndexes) async {
    final result = await voteFeedPollUseCase(postId, optionIndexes);
    return result.fold((message) => message, (newPoll) {
      final target = _findItem(postId);
      if (target != null) _replaceItem(target.copyWith(poll: newPoll));
      FeedLiveStats.instance.markLocalChange(postId);
      return null;
    });
  }

  FeedPostEntity? _findItem(int postId) {
    for (final p in state.items) {
      if (p.id == postId) return p;
    }
    return null;
  }

  void _replaceItem(FeedPostEntity post) {
    final index = state.items.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    final items = [...state.items]..[index] = post;
    emit(_copy(items: items));
  }

  /// Muat ulang dari halaman pertama untuk tab yang aktif. userId null = profil sendiri.
  Future<void> fetch({int? userId}) async {
    _userId = userId;
    emit(_copy(status: MyProfileStatus.loading));
    await _load(page: 1, append: false);
  }

  /// Ganti tab: kumpulan kartu dikosongkan, lalu halaman pertama tab baru dimuat.
  Future<void> setTab(ProfileTab tab) async {
    if (tab == state.tab) return;
    emit(
      _copy(
        status: MyProfileStatus.loading,
        tab: tab,
        items: const [],
        page: 1,
        hasMore: false,
      ),
    );
    await _load(page: 1, append: false);
  }

  /// Halaman berikutnya untuk tab aktif (dipanggil saat scroll mendekati bawah).
  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    if (state.status == MyProfileStatus.loading) return;
    emit(_copy(loadingMore: true));
    await _load(page: state.page + 1, append: true);
  }

  Future<void> _load({required int page, required bool append}) async {
    final token = ++_seq;
    final tab = state.tab;
    final result = await getMyProfileUseCase(
      userId: _userId,
      tab: tab.api,
      page: page,
      perPage: _perPage,
    );
    if (isClosed || token != _seq) return;

    result.fold(
      (message) => emit(
        _copy(
          status: MyProfileStatus.error,
          errorMessage: message,
          loadingMore: false,
        ),
      ),
      (data) => emit(
        _copy(
          status: MyProfileStatus.loaded,
          profile: data,
          items: append ? [...state.items, ...data.items] : data.items,
          page: data.currentPage,
          hasMore: data.hasMore,
          loadingMore: false,
          errorMessage: null,
        ),
      ),
    );
  }

  /// Salinan state dengan field tertentu diganti. Field yang tidak diisi ikut state sekarang.
  MyProfileState _copy({
    MyProfileStatus? status,
    MyProfileEntity? profile,
    ProfileTab? tab,
    List<FeedPostEntity>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? errorMessage,
  }) {
    return MyProfileState(
      status: status ?? state.status,
      profile: profile ?? state.profile,
      tab: tab ?? state.tab,
      items: items ?? state.items,
      page: page ?? state.page,
      hasMore: hasMore ?? state.hasMore,
      loadingMore: loadingMore ?? state.loadingMore,
      errorMessage: errorMessage,
    );
  }
}
