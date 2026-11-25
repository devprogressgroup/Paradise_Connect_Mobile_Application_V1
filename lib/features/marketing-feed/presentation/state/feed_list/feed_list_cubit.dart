import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_list_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

enum FeedListStatus { initial, loading, loaded, error }

/// Status yang bisa difilter. Ditinjau berisi semua review untuk approver (ApproveReject), dan review sendiri untuk yang lain.
const feedListStatusOptions = <(String, String)>[
  ('published', 'Publish'),
  ('draft', 'Draf'),
  ('scheduled', 'Terjadwal'),
  ('review', 'Ditinjau'),
  ('rejected', 'Ditolak'),
];

/// Jenis baris di daftar: kiriman (post) dan kartu Wall of Fame (fame).
const feedListKindOptions = <(String, String)>[
  ('post', 'Kiriman'),
  ('fame', 'Wall of Fame'),
];

const feedListSortOptions = <(String, String)>[
  ('latest', 'Terbaru'),
  ('oldest', 'Terlama'),
  ('updated', 'Terakhir diubah'),
];

class FeedListState {
  final FeedListStatus status;
  final List<FeedListItem> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final String query;
  final String sort;

  /// Status dan jenis yang dipilih. Kosong = semua.
  final Set<String> statuses;
  final Set<String> kinds;
  /// Dilaporkan (approver): kiriman dengan laporan terbuka ikut tampil (tanpa status = hanya yang dilaporkan).
  final bool reported;
  /// Tidak ada yang dicentang di sheet filter: daftar kosong dengan pesan, tanpa memanggil server.
  final bool noSelection;

  /// Kunci baris yang sedang diproses (lihat [FeedListItem.key]).
  final String? busyKey;
  final String? errorMessage;

  const FeedListState({
    this.status = FeedListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.query = '',
    this.sort = 'latest',
    this.statuses = const {'published'},
    this.kinds = const {'post'},
    this.reported = false,
    this.noSelection = false,
    this.busyKey,
    this.errorMessage,
  });

  /// Filter default = hanya Tayang.
  bool get isDefaultStatuses => statuses.length == 1 && statuses.contains('published');
  /// Default jenis = kiriman saja (Wall of Fame tidak ikut).
  bool get isDefaultKinds => kinds.length == 1 && kinds.contains('post');

  bool get filtered =>
      query.isNotEmpty || !isDefaultStatuses || !isDefaultKinds || reported;

  FeedListState copyWith({
    FeedListStatus? status,
    List<FeedListItem>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? query,
    String? sort,
    Set<String>? statuses,
    Set<String>? kinds,
    bool? reported,
    bool? noSelection,
    String? busyKey,
    String? errorMessage,
    bool clearBusy = false,
    bool clearError = false,
  }) {
    return FeedListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      statuses: statuses ?? this.statuses,
      kinds: kinds ?? this.kinds,
      reported: reported ?? this.reported,
      noSelection: noSelection ?? this.noSelection,
      busyKey: clearBusy ? null : (busyKey ?? this.busyKey),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Daftar Feeds terpadu: kiriman dan Wall of Fame, dengan pencarian, filter, urutan, dan paginasi dari server.
/// Aksi (setujui, tolak, jadwalkan, turunkan tayang, hapus, sematkan, tayangkan kartu fame) lewat sini
/// supaya daftar langsung diperbarui.
class FeedListCubit extends Cubit<FeedListState> {
  final MarketingFeedRepository repository;

  static const _perPage = 15;
  static const _searchDelay = Duration(milliseconds: 400);

  Timer? _searchTimer;
  // Balasan permintaan yang sudah tidak relevan (filter/urutan sudah berubah) dibuang.
  int _requestSeq = 0;

  FeedListCubit({required this.repository}) : super(const FeedListState());

  /// Muat halaman pertama. [silent] = pembaruan berkala tanpa indikator loading.
  Future<void> load({bool silent = false}) async {
    if (state.noSelection) return;
    final seq = ++_requestSeq;
    if (!silent) {
      emit(state.copyWith(status: FeedListStatus.loading, clearError: true));
    }
    final result = await repository.getFeedList(
      page: 1,
      perPage: _perPage,
      statuses: state.statuses.toList(),
      kinds: state.kinds.toList(),
      q: state.query,
      sort: state.sort,
      reported: state.reported,
    );
    if (isClosed || seq != _requestSeq) return;
    result.fold(
      (message) {
        // Pembaruan berkala yang gagal tidak menghapus daftar yang sudah tampil.
        if (silent && state.items.isNotEmpty) return;
        emit(state.copyWith(status: FeedListStatus.error, errorMessage: message));
      },
      (page) => emit(
        state.copyWith(
          status: FeedListStatus.loaded,
          items: page.items,
          page: page.currentPage,
          hasMore: page.hasMore,
          clearError: true,
        ),
      ),
    );
  }

  /// Halaman berikutnya saat daftar di-scroll ke bawah.
  Future<void> loadMore() async {
    if (state.noSelection) return;
    if (!state.hasMore || state.loadingMore || state.status == FeedListStatus.loading) return;
    final seq = _requestSeq;
    emit(state.copyWith(loadingMore: true));
    final result = await repository.getFeedList(
      page: state.page + 1,
      perPage: _perPage,
      statuses: state.statuses.toList(),
      kinds: state.kinds.toList(),
      q: state.query,
      sort: state.sort,
      reported: state.reported,
    );
    if (isClosed || seq != _requestSeq) return;
    result.fold(
      (_) => emit(state.copyWith(loadingMore: false)),
      (page) => emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          page: page.currentPage,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      ),
    );
  }

  /// Pencarian diketik: daftar dimuat ulang setelah jeda pendek supaya tidak memanggil server di setiap huruf.
  void setQuery(String value) {
    final q = value.trim();
    if (q == state.query) return;
    emit(state.copyWith(query: q));
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDelay, () => load());
  }

  /// Kosong atau berisi semua pilihan = tanpa filter (tampilkan semua).
  void setFilter({required Set<String> statuses, required Set<String> kinds, bool reported = false}) {
    final allStatuses = statuses.length >= feedListStatusOptions.length;
    final allKinds = kinds.length >= feedListKindOptions.length;
    emit(
      state.copyWith(
        statuses: allStatuses && !reported ? const {} : statuses,
        kinds: allKinds ? const {} : kinds,
        reported: reported,
        noSelection: false,
      ),
    );
    load();
  }

  /// Hasil sheet filter, dipakai persis seperti yang dicentang (tanpa menambah atau mengurangi).
  /// Status kosong dan Dilaporkan tidak dicentang = tidak ada yang dipilih, daftar kosong.
  /// Dilaporkan menambah kiriman yang punya laporan terbuka, dari status apa pun.
  /// Wall of Fame: kartu fame ikut tampil hanya kalau ada status yang dicentang.
  void applySheet({required Set<String> statuses, required bool reported, required bool includeFame}) {
    final none = statuses.isEmpty && !reported;
    // Hanya Dilaporkan: kiriman saja. Ada status: kiriman, plus kartu fame kalau Wall of Fame dicentang.
    final kinds = statuses.isEmpty || !includeFame ? <String>{'post'} : <String>{};
    emit(
      state.copyWith(
        statuses: statuses,
        kinds: kinds,
        reported: reported,
        noSelection: none,
        items: none ? const [] : state.items,
        status: none ? FeedListStatus.loaded : state.status,
      ),
    );
    if (!none) load();
  }

  void setSort(String sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    load();
  }

  /// approve | schedule (perlu [publishAt]) | reject (perlu [reason]). Balikan: pesan error atau null.
  Future<String?> decide(
    int postId,
    String decision, {
    String? reason,
    String? publishAt,
  }) async {
    emit(state.copyWith(busyKey: _postKey(postId)));
    final result = await repository.decideReview(
      postId,
      decision,
      reason: reason,
      publishAt: publishAt,
    );
    if (isClosed) return null;
    return result.fold(
      (message) {
        emit(state.copyWith(clearBusy: true));
        return message;
      },
      (_) {
        emit(state.copyWith(clearBusy: true));
        load(silent: true);
        return null;
      },
    );
  }

  /// 'unpub' = turunkan tayang (kembali ke draf), 'del' = hapus kiriman. Balikan: pesan error atau null.
  Future<String?> moderate(int postId, String action) async {
    emit(state.copyWith(busyKey: _postKey(postId)));
    final result = await repository.moderatorAction(postId, action);
    if (isClosed) return null;
    return result.fold(
      (message) {
        emit(state.copyWith(clearBusy: true));
        return message;
      },
      (_) {
        emit(
          state.copyWith(
            clearBusy: true,
            items: state.items.where((i) => i.post?.id != postId).toList(),
          ),
        );
        load(silent: true);
        return null;
      },
    );
  }

  /// Sematkan / lepas sematan di profil (hanya kiriman sendiri). Balikan: pesan error atau null.
  Future<String?> setProfilePin(int postId, {required bool pinned}) async {
    final result = await repository.setProfilePin(postId, pinned: pinned);
    if (isClosed) return null;
    return result.fold(
      (message) => message,
      (_) {
        emit(
          state.copyWith(
            items: [
              for (final i in state.items)
                i.post?.id == postId
                    ? FeedListItem.post(i.post!.copyWith(profilePinned: pinned))
                    : i,
            ],
          ),
        );
        return null;
      },
    );
  }

  /// Publish" / kembalikan ke draf / jadwalkan kartu Wall of Fame ('published' | 'draft'). Balikan: pesan error atau null.
  Future<String?> setFameStatus(int cardId, String status) async {
    emit(state.copyWith(busyKey: _fameKey(cardId)));
    final result = await repository.setFameCardStatus(cardId, status, null);
    if (isClosed) return null;
    return result.fold(
      (message) {
        emit(state.copyWith(clearBusy: true));
        return message;
      },
      (_) {
        emit(state.copyWith(clearBusy: true));
        load(silent: true);
        return null;
      },
    );
  }

  /// Hapus kartu Wall of Fame (beserta juara dan posternya). Balikan: pesan error atau null.
  Future<String?> deleteFame(int cardId) async {
    emit(state.copyWith(busyKey: _fameKey(cardId)));
    final result = await repository.deleteFameCard(cardId);
    if (isClosed) return null;
    return result.fold(
      (message) {
        emit(state.copyWith(clearBusy: true));
        return message;
      },
      (_) {
        emit(
          state.copyWith(
            clearBusy: true,
            items: state.items.where((i) => i.fame?.id != cardId).toList(),
          ),
        );
        load(silent: true);
        return null;
      },
    );
  }

  String _postKey(int id) => 'p$id';
  String _fameKey(int id) => 'f$id';

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}
