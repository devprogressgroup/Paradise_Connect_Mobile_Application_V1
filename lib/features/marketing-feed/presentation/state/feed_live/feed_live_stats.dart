import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_stats_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/repositories/marketing_feed_repository.dart';

/// Polling statistik kiriman yang sedang terlihat: like, dislike, komentar, dan komentar terbaru.
///
/// Hanya kartu yang sedang dibangun (terlihat plus sedikit cache) yang dipantau, sehingga
/// kartu yang sudah lewat layar tidak ikut diminta. Berhenti saat app di background.
/// Hasil disimpan per kiriman di [of]. Setiap kartu hanya mendengarkan kiriman miliknya,
/// jadi perubahan satu kiriman tidak membuat semua kartu rebuild.
class FeedLiveStats with WidgetsBindingObserver {
  FeedLiveStats._();
  static final FeedLiveStats instance = FeedLiveStats._();

  static const _interval = Duration(seconds: 20);
  static const _maxPerRequest = 20;

  final Map<int, ValueNotifier<FeedStatsEntity?>> _notifiers = {};
  final Map<int, DateTime> _localAt = {};

  /// Notifier statistik satu kiriman. Null = belum ada data polling untuk kiriman itu.
  ValueNotifier<FeedStatsEntity?> of(int postId) =>
      _notifiers.putIfAbsent(postId, () => ValueNotifier<FeedStatsEntity?>(null));

  MarketingFeedRepository? _repo;
  final Map<int, int> _watchers = {};
  Timer? _timer;
  bool _foreground = true;
  bool _busy = false;
  bool _observing = false;

  /// Kiriman yang baru diubah lokal (like, dislike). Data polling lama untuk kiriman itu dibuang,
  /// dan hasil polling yang sudah berjalan sebelum perubahan ini tidak dipakai, supaya angka lama
  /// tidak menimpa hasil like barusan. Angka server akan masuk lagi di polling berikutnya.
  void markLocalChange(int postId) {
    _localAt[postId] = DateTime.now();
    of(postId).value = null;
  }

  /// Dipanggil sekali saat app dibuka (main.dart), dengan repository feed yang sudah ada.
  void attach(MarketingFeedRepository repo) {
    _repo = repo;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
  }

  void watch(int postId) {
    _watchers[postId] = (_watchers[postId] ?? 0) + 1;
    if (_timer == null && _foreground) {
      _start();
      _tick();
    }
  }

  void unwatch(int postId) {
    final n = (_watchers[postId] ?? 1) - 1;
    if (n <= 0) {
      _watchers.remove(postId);
    } else {
      _watchers[postId] = n;
    }
    if (_watchers.isEmpty) _stop();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && _watchers.isNotEmpty) {
      _start();
      _tick();
    } else if (!_foreground) {
      _stop();
    }
  }

  Future<void> _tick() async {
    final repo = _repo;
    if (repo == null || _watchers.isEmpty || _busy) return;
    _busy = true;
    try {
      // Kartu yang paling baru dibangun (paling dekat dengan layar) diprioritaskan.
      final ids = _watchers.keys.toList().reversed.take(_maxPerRequest).toList();
      final started = DateTime.now();
      final result = await repo.getFeedStats(ids);
      result.fold((_) {}, (list) {
        for (final s in list) {
          // Kiriman yang diubah lokal sesudah polling ini dimulai: abaikan data polling ini untuknya.
          final local = _localAt[s.id];
          if (local != null && local.isAfter(started)) continue;
          // Hanya kiriman yang benar-benar berubah yang memberi tahu kartunya.
          final n = of(s.id);
          if (n.value != s) n.value = s;
        }
      });
    } finally {
      _busy = false;
    }
  }
}

/// Mendaftarkan kiriman ke polling selama widget ini ada di layar (initState sampai dispose).
class FeedLiveWatch extends StatefulWidget {
  final int postId;
  final Widget child;

  const FeedLiveWatch({super.key, required this.postId, required this.child});

  @override
  State<FeedLiveWatch> createState() => _FeedLiveWatchState();
}

class _FeedLiveWatchState extends State<FeedLiveWatch> {
  @override
  void initState() {
    super.initState();
    FeedLiveStats.instance.watch(widget.postId);
  }

  @override
  void didUpdateWidget(covariant FeedLiveWatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      FeedLiveStats.instance.unwatch(oldWidget.postId);
      FeedLiveStats.instance.watch(widget.postId);
    }
  }

  @override
  void dispose() {
    FeedLiveStats.instance.unwatch(widget.postId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
