import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/pages/calendar/calendar_route_args.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_calendar/feed_calendar_cubit.dart';
import 'package:progress_group/features/marketing-feed/presentation/state/feed_calendar/feed_calendar_state.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_calendar_views.dart';

/// Kalender Jadwal (moderator): kiriman terjadwal dan tayang per tanggal, tampilan Bulan / Minggu / Hari.
/// Ketuk kiriman terjadwal untuk mengubahnya, kiriman tayang membuka detailnya. Tombol + membuat
/// Postingan / Polling / Link untuk tanggal yang sedang dipilih (sesuai permission masing-masing).
class FeedCalendarPage extends StatefulWidget {
  const FeedCalendarPage({super.key});

  @override
  State<FeedCalendarPage> createState() => _FeedCalendarPageState();
}

/// Jam default kiriman baru dari kalender, sama dengan prototype (09:00).
const int _defaultHour = 9;

class _FeedCalendarPageState extends State<FeedCalendarPage> {
  FeedCalendarView _view = FeedCalendarView.bulan;

  /// Tanggal yang dipilih (jam dinding WIB, tanpa jam).
  late DateTime _selected;

  /// Rentang yang sedang dimuat, supaya tidak memuat ulang rentang yang sama.
  DateTime? _loadedFrom;
  DateTime? _loadedTo;

  static final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final _dayFormat = DateFormat('EEEE, d MMMM', 'id_ID');
  static final _dayYearFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final _shortFormat = DateFormat('d MMM', 'id_ID');
  static final _shortYearFormat = DateFormat('d MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('marketing_feed_calendar');
    _selected = _today;
    _load(force: true);
  }

  DateTime get _today {
    final now = AppTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  /// Rentang tanggal yang perlu dimuat untuk tampilan dan tanggal terpilih.
  /// Bulan = grid 6 minggu (Senin–Minggu) dari tanggal grid pertama.
  (DateTime, DateTime) _rangeFor(FeedCalendarView view, DateTime s) {
    switch (view) {
      case FeedCalendarView.bulan:
        final first = DateTime(s.year, s.month, 1);
        final start = _addDays(first, -(first.weekday - 1));
        return (start, _addDays(start, 41));
      case FeedCalendarView.minggu:
        final start = _addDays(s, -(s.weekday - 1));
        return (start, _addDays(start, 6));
      case FeedCalendarView.hari:
        return (s, s);
    }
  }

  Future<void> _load({bool force = false}) {
    final (from, to) = _rangeFor(_view, _selected);
    final same =
        _loadedFrom != null &&
        _loadedTo != null &&
        isSameDay(from, _loadedFrom!) &&
        isSameDay(to, _loadedTo!);
    if (!force && same) return Future.value();
    _loadedFrom = from;
    _loadedTo = to;
    return context.read<FeedCalendarCubit>().fetch(from: from, to: to);
  }

  void _setView(FeedCalendarView view) {
    if (view == _view) return;
    setState(() => _view = view);
    _load();
  }

  void _select(DateTime day) {
    setState(() => _selected = DateTime(day.year, day.month, day.day));
    _load();
  }

  void _shift(int dir) {
    final s = _selected;
    final next = switch (_view) {
      FeedCalendarView.bulan => DateTime(s.year, s.month + dir, 1),
      FeedCalendarView.minggu => _addDays(s, 7 * dir),
      FeedCalendarView.hari => _addDays(s, dir),
    };
    _select(next);
  }

  Map<int, List<FeedPostEntity>> _byDay(List<FeedPostEntity> items) {
    final map = <int, List<FeedPostEntity>>{};
    for (final p in items) {
      map.putIfAbsent(dayKey(p.publishAt), () => []).add(p);
    }
    return map;
  }

  List<FeedPostEntity> _sortedOn(
    Map<int, List<FeedPostEntity>> byDay,
    DateTime day,
  ) {
    final list = [...(byDay[dayKey(day)] ?? const <FeedPostEntity>[])];
    list.sort((a, b) => a.publishAt.compareTo(b.publishAt));
    return list;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _headerTitle() {
    final s = _selected;
    switch (_view) {
      case FeedCalendarView.bulan:
        return _capitalize(_monthFormat.format(DateTime(s.year, s.month)));
      case FeedCalendarView.minggu:
        final (from, to) = _rangeFor(_view, s);
        return '${_shortFormat.format(from)} – ${_shortYearFormat.format(to)}';
      case FeedCalendarView.hari:
        return _shortYearFormat.format(s);
    }
  }

  String _navLabel() {
    final s = _selected;
    switch (_view) {
      case FeedCalendarView.bulan:
        return _capitalize(_monthFormat.format(DateTime(s.year, s.month)));
      case FeedCalendarView.minggu:
        final (from, to) = _rangeFor(_view, s);
        return '${_shortFormat.format(from)} – ${_shortYearFormat.format(to)}';
      case FeedCalendarView.hari:
        final isToday = isSameDay(s, _today);
        return '${_capitalize(_dayYearFormat.format(s))}${isToday ? ' (hari ini)' : ''}';
    }
  }

  /// Ubah tanggal, bulan, dan tahun lewat lembar bawah (tombol pensil di judul).
  Future<void> _openDatePicker() async {
    final s = _selected;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _DatePickerSheet(initial: s),
    );
    if (picked != null) _select(picked);
  }

  bool get _canCreate =>
      PermissionsHelper.canCreateMarketingPost ||
      PermissionsHelper.canCreateMarketingPoll ||
      PermissionsHelper.canCreateMarketingLink;

  /// Waktu default kiriman baru di tanggal [day]: 09:00, atau satu jam dari sekarang kalau 09:00 sudah lewat.
  DateTime _defaultTimeOn(DateTime day) {
    final at = DateTime.utc(day.year, day.month, day.day, _defaultHour);
    final now = AppTime.now();
    if (at.isAfter(now)) return at;
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(hours: 1));
  }

  /// Tombol +: buat konten baru untuk tanggal terpilih. Tanggal lampau diganti hari ini.
  Future<void> _onAdd() async {
    final today = _today;
    final day = _selected.isBefore(today) ? today : _selected;
    final at = _defaultTimeOn(day);
    final options = <(String, IconData, String)>[
      if (PermissionsHelper.canCreateMarketingPost)
        ('Postingan', Icons.article_outlined, 'marketingFeedPostForm'),
      if (PermissionsHelper.canCreateMarketingPoll)
        ('Polling', Icons.poll_outlined, 'marketingFeedPollForm'),
      if (PermissionsHelper.canCreateMarketingLink)
        ('Link', Icons.link, 'marketingFeedLinkForm'),
    ];
    if (options.isEmpty) return;

    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Text(
                  'Jadwalkan untuk ${_dayYearFormat.format(day)}, ${DateFormat('HH:mm').format(at)}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final (label, icon, route) in options)
                ListTile(
                  leading: Icon(icon, color: const Color(primaryColor)),
                  title: Text(label),
                  onTap: () => Navigator.pop(ctx, route),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    AnalyticsService.logEvent('marketing_feed_calendar_add');
    await context.pushNamed<bool>(
      chosen,
      // Tanggal jadwal hanya dikirim kalau user punya SetSchedule; kalau tidak, form dibuka sebagai "Sekarang".
      queryParameters: PermissionsHelper.canSetScheduleMarketingFeed
          ? FeedCalendarRouteArgs.forSchedule(at)
          : {
              FeedCalendarRouteArgs.sourceKey:
                  FeedCalendarRouteArgs.sourceCalendar,
            },
    );
    if (mounted) _load(force: true);
  }

  /// Kiriman terjadwal dibuka di form (sama dengan Draft & Terjadwal); kiriman tayang di halaman detail.
  Future<void> _openPost(FeedPostEntity post) async {
    if (isPublishedPost(post)) {
      await context.pushNamed(
        'marketingFeedDetail',
        queryParameters: {'feed_post_id': '${post.id}'},
      );
    } else {
      final route = switch (post.type) {
        FeedPostType.post => 'marketingFeedPostForm',
        FeedPostType.poll => 'marketingFeedPollForm',
        FeedPostType.link => 'marketingFeedLinkForm',
      };
      final saved = await context.pushNamed<bool>(route, extra: post);
      if (saved != true) return;
    }
    if (mounted) _load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(
              context,
              _headerTitle(),
              isBack: true,
              trailing: IconButton(
                tooltip: 'Ubah tanggal, bulan, atau tahun',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: _openDatePicker,
              ),
            ),
            Expanded(
              child: BlocBuilder<FeedCalendarCubit, FeedCalendarState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () => _load(force: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      children: [
                        FeedCalendarModeBar(view: _view, onChanged: _setView),
                        const SizedBox(height: 8),
                        if (state.status == FeedCalendarStatus.error &&
                            state.items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Column(
                              children: [
                                Text(
                                  state.errorMessage ??
                                      'Gagal memuat kalender jadwal.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(grey2Color),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => _load(force: true),
                                  child: const Text('Coba lagi'),
                                ),
                              ],
                            ),
                          )
                        else if (state.status == FeedCalendarStatus.loading &&
                            state.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          ..._buildBody(state.items),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              heroTag: 'feed_calendar_fab',
              tooltip: 'Buat konten untuk tanggal ini',
              onPressed: _onAdd,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  List<Widget> _buildBody(List<FeedPostEntity> items) {
    final byDay = _byDay(items);
    final today = _today;
    switch (_view) {
      case FeedCalendarView.bulan:
        return _buildMonth(byDay, today);
      case FeedCalendarView.minggu:
        return _buildWeek(byDay, today);
      case FeedCalendarView.hari:
        return _buildDay(byDay, today);
    }
  }

  List<Widget> _buildMonth(
    Map<int, List<FeedPostEntity>> byDay,
    DateTime today,
  ) {
    final s = _selected;
    final first = DateTime(s.year, s.month, 1);
    final gridStart = _addDays(first, -(first.weekday - 1));
    final dayItems = _sortedOn(byDay, s);
    final dayLabel = _capitalize(_dayFormat.format(s));
    final isToday = isSameDay(s, today);

    return [
      FeedCalendarNavRow(
        label: _navLabel(),
        onPrev: () => _shift(-1),
        onNext: () => _shift(1),
      ),
      FeedCalendarMonthGrid(
        gridStart: gridStart,
        month: s.month,
        selected: s,
        today: today,
        byDay: byDay,
        onSelect: _select,
      ),
      const SizedBox(height: 10),
      const FeedCalendarLegend(),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              isToday ? 'Hari ini · $dayLabel' : dayLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${dayItems.length} postingan',
            style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (dayItems.isEmpty)
        const FeedCalendarEmpty(
          message:
              'Belum ada kiriman di tanggal ini.\nKetuk + untuk menjadwalkan.',
        )
      else
        for (final p in dayItems) ...[
          FeedCalendarAgendaRow(post: p, onTap: () => _openPost(p)),
          const SizedBox(height: 8),
        ],
    ];
  }

  List<Widget> _buildWeek(
    Map<int, List<FeedPostEntity>> byDay,
    DateTime today,
  ) {
    final (weekStart, _) = _rangeFor(_view, _selected);
    final days = [for (var i = 0; i < 7; i++) _addDays(weekStart, i)];
    final withItems = [
      for (final d in days)
        if (byDay[dayKey(d)] != null && byDay[dayKey(d)]!.isNotEmpty) d,
    ];

    return [
      FeedCalendarNavRow(
        label: _navLabel(),
        onPrev: () => _shift(-1),
        onNext: () => _shift(1),
      ),
      FeedCalendarWeekStrip(
        weekStart: weekStart,
        selected: _selected,
        today: today,
        byDay: byDay,
        onSelect: _select,
      ),
      const SizedBox(height: 16),
      if (withItems.isEmpty)
        const FeedCalendarEmpty(message: 'Belum ada kiriman di minggu ini.')
      else
        for (final d in withItems)
          FeedCalendarAgendaDay(
            day: d,
            isToday: isSameDay(d, today),
            items: _sortedOn(byDay, d),
            onTap: _openPost,
          ),
    ];
  }

  List<Widget> _buildDay(Map<int, List<FeedPostEntity>> byDay, DateTime today) {
    final s = _selected;
    final items = _sortedOn(byDay, s);
    return [
      FeedCalendarNavRow(
        label: _navLabel(),
        onPrev: () => _shift(-1),
        onNext: () => _shift(1),
      ),
      const SizedBox(height: 8),
      if (items.isEmpty)
        const FeedCalendarEmpty(message: 'Belum ada kiriman di tanggal ini.')
      else
        FeedCalendarAgendaDay(
          day: s,
          isToday: isSameDay(s, today),
          items: items,
          onTap: _openPost,
        ),
    ];
  }
}

/// Lembar "Ubah tanggal": pilih tanggal, bulan, dan tahun. Jumlah hari mengikuti bulan dan tahun.
class _DatePickerSheet extends StatefulWidget {
  final DateTime initial;

  const _DatePickerSheet({required this.initial});

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late int _day = widget.initial.day;
  late int _month = widget.initial.month;
  late int _year = widget.initial.year;

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final maxDay = _daysInMonth;
    final day = _day > maxDay ? maxDay : _day;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah tanggal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'Tanggal',
                    DropdownButton<int>(
                      isExpanded: true,
                      value: day,
                      items: [
                        for (var d = 1; d <= maxDay; d++)
                          DropdownMenuItem(value: d, child: Text('$d')),
                      ],
                      onChanged: (v) => setState(() => _day = v ?? day),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _field(
                    'Bulan',
                    DropdownButton<int>(
                      isExpanded: true,
                      value: _month,
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(
                            value: m,
                            child: Text(_monthNames[m - 1]),
                          ),
                      ],
                      onChanged: (v) => setState(() => _month = v ?? _month),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _field(
                    'Tahun',
                    DropdownButton<int>(
                      isExpanded: true,
                      value: _year,
                      items: [
                        for (var y = _year - 10; y <= _year + 10; y++)
                          DropdownMenuItem(value: y, child: Text('$y')),
                      ],
                      onChanged: (v) => setState(() => _year = v ?? _year),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, DateTime(_year, _month, day)),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(grey2Color),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(grey7Color)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ],
    );
  }
}
