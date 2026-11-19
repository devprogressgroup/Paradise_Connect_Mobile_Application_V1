import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';

/// Tampilan Kalender Jadwal: Bulan (grid + agenda hari terpilih), Minggu, Hari.
enum FeedCalendarView { bulan, minggu, hari }

const _schedDot = Color(primaryColor);
const _pubDot = Color(successColor);
const _schedBlock = Color(0xFF64B5F6);
const _pubBlock = Color(0xFF4DB6AC);
const _schedBlockText = Color(0xFF0D2B45);
const _pubBlockText = Color(0xFF06302C);

/// Kunci hari (yyyymmdd) untuk mengelompokkan kiriman per tanggal.
int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isPublishedPost(FeedPostEntity p) => p.status == FeedPostStatus.published;

String feedPostTypeLabel(FeedPostType t) => switch (t) {
  FeedPostType.post => 'Postingan',
  FeedPostType.poll => 'Polling',
  FeedPostType.link => 'Link',
};

/// Judul singkat untuk baris agenda; kiriman tanpa teks memakai nama jenisnya.
String feedPostAgendaTitle(FeedPostEntity p) {
  final title = p.plainText.trim();
  return title.isEmpty ? feedPostTypeLabel(p.type) : title;
}

String _subtitle(FeedPostEntity p) {
  final township = p.township?.code ?? 'Semua township';
  final state = isPublishedPost(p) ? 'sudah tayang' : 'terjadwal';
  return '${feedPostTypeLabel(p.type)} · $township · $state';
}

String _hhmm(DateTime d) => DateFormat('HH:mm').format(d);

/// Pilihan Bulan / Minggu / Hari.
class FeedCalendarModeBar extends StatelessWidget {
  final FeedCalendarView view;
  final ValueChanged<FeedCalendarView> onChanged;

  const FeedCalendarModeBar({
    super.key,
    required this.view,
    required this.onChanged,
  });

  static const _labels = {
    FeedCalendarView.bulan: 'Bulan',
    FeedCalendarView.minggu: 'Minggu',
    FeedCalendarView.hari: 'Hari',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(grey10Color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final entry in _labels.entries)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onChanged(entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: entry.key == view
                        ? const Color(whiteColor)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: entry.key == view
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: entry.key == view
                          ? const Color(primaryColor)
                          : const Color(grey2Color),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Baris "‹  label  ›" untuk pindah bulan, minggu, atau hari.
class FeedCalendarNavRow extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const FeedCalendarNavRow({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Sebelumnya',
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: 'Berikutnya',
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// Grid bulan Senin-pertama, 6 baris. Titik per kiriman: biru = terjadwal, hijau = tayang.
class FeedCalendarMonthGrid extends StatelessWidget {
  /// Tanggal pertama di grid (Senin sebelum / pada tanggal 1).
  final DateTime gridStart;
  final int month;
  final DateTime selected;
  final DateTime today;
  final Map<int, List<FeedPostEntity>> byDay;
  final ValueChanged<DateTime> onSelect;

  const FeedCalendarMonthGrid({
    super.key,
    required this.gridStart,
    required this.month,
    required this.selected,
    required this.today,
    required this.byDay,
    required this.onSelect,
  });

  static const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(grey2Color),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 0.9,
          children: [
            for (var i = 0; i < 42; i++) _buildCell(context, _addDays(i)),
          ],
        ),
      ],
    );
  }

  DateTime _addDays(int n) =>
      DateTime(gridStart.year, gridStart.month, gridStart.day + n);

  Widget _buildCell(BuildContext context, DateTime day) {
    final inMonth = day.month == month;
    final isSelected = isSameDay(day, selected);
    final isToday = isSameDay(day, today);
    final items = byDay[dayKey(day)] ?? const <FeedPostEntity>[];

    final Color textColor;
    if (isSelected) {
      textColor = const Color(whiteColor);
    } else if (isToday) {
      textColor = const Color(primaryColor);
    } else if (inMonth) {
      textColor = const Color(blackColor);
    } else {
      textColor = const Color(grey5Color);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelect(day),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(primaryColor)
              : (inMonth ? const Color(whiteColor) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          boxShadow: inMonth && !isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final p in items.take(3))
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(whiteColor)
                            : (isPublishedPost(p) ? _pubDot : _schedDot),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legenda titik: Terjadwal (biru), Tayang (hijau).
class FeedCalendarLegend extends StatelessWidget {
  const FeedCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: Color(grey2Color),
    );
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: _schedDot),
        SizedBox(width: 5),
        Text('Terjadwal', style: style),
        SizedBox(width: 14),
        _LegendDot(color: _pubDot),
        SizedBox(width: 5),
        Text('Tayang', style: style),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Strip 7 hari untuk tampilan Minggu.
class FeedCalendarWeekStrip extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selected;
  final DateTime today;
  final Map<int, List<FeedPostEntity>> byDay;
  final ValueChanged<DateTime> onSelect;

  const FeedCalendarWeekStrip({
    super.key,
    required this.weekStart,
    required this.selected,
    required this.today,
    required this.byDay,
    required this.onSelect,
  });

  static const _short = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++) Expanded(child: _buildDay(context, i)),
      ],
    );
  }

  Widget _buildDay(BuildContext context, int i) {
    final day = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
    final isSelected = isSameDay(day, selected);
    final isToday = isSameDay(day, today);
    final count = (byDay[dayKey(day)] ?? const <FeedPostEntity>[]).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelect(day),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(primaryColor)
                : const Color(whiteColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                _short[i],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(whiteColor)
                      : const Color(grey2Color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(whiteColor)
                      : (isToday
                            ? const Color(primaryColor)
                            : const Color(blackColor)),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 6,
                child: count == 0
                    ? null
                    : Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(whiteColor)
                              : _schedDot,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris kiriman untuk agenda tanggal terpilih (tampilan Bulan).
class FeedCalendarAgendaRow extends StatelessWidget {
  final FeedPostEntity post;
  final VoidCallback onTap;

  const FeedCalendarAgendaRow({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final published = isPublishedPost(post);
    return Material(
      color: const Color(whiteColor),
      borderRadius: BorderRadius.circular(10),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _hhmm(post.publishAt),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(grey2Color),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: published ? _pubDot : _schedDot,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedPostAgendaTitle(post),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(blackColor),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(post),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(grey2Color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu hari di agenda Minggu / Hari: kolom tanggal + blok kiriman berwarna.
class FeedCalendarAgendaDay extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final List<FeedPostEntity> items;
  final ValueChanged<FeedPostEntity> onTap;

  const FeedCalendarAgendaDay({
    super.key,
    required this.day,
    required this.isToday,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = DateFormat('EEE', 'id_ID').format(day);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  weekday,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(grey2Color),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(primaryColor)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? const Color(whiteColor)
                          : const Color(blackColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                for (final p in items) ...[
                  FeedCalendarAgendaBlock(post: p, onTap: () => onTap(p)),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Blok kiriman di agenda Minggu / Hari: biru = terjadwal, teal = tayang.
class FeedCalendarAgendaBlock extends StatelessWidget {
  final FeedPostEntity post;
  final VoidCallback onTap;

  const FeedCalendarAgendaBlock({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final published = isPublishedPost(post);
    final textColor = published ? _pubBlockText : _schedBlockText;
    return Material(
      color: published ? _pubBlock : _schedBlock,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _hhmm(post.publishAt),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                feedPostAgendaTitle(post),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _subtitle(post),
                style: TextStyle(
                  fontSize: 11.5,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Teks kosong untuk agenda tanpa kiriman.
class FeedCalendarEmpty extends StatelessWidget {
  final String message;

  const FeedCalendarEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(grey2Color)),
        ),
      ),
    );
  }
}
