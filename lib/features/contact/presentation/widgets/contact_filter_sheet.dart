import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/features/contact/data/models/dropdown/contact_filter_result.dart';
import 'package:progress_group/features/contact/domain/entities/dropdown_option.dart';

class _DatePreset {
  final String label;
  final DateTime start;
  final DateTime end;
  const _DatePreset(this.label, this.start, this.end);
}

const _dateDims = [
  (key: 'create', label: 'Create Date'),
  (key: 'appt', label: 'Appt Date'),
  (key: 'visit', label: 'Visit Date'),
  (key: 'reserve', label: 'Reserve Date'),
  (key: 'sp', label: 'SP Date'),
  (key: 'lost', label: 'Lost Date'),
];

class ContactFilterSheet extends StatefulWidget {
  final List<ContactCheckGroup> checkGroups;
  final List<PaginatedCheckGroup> paginatedGroups;
  final Map<String, Set<int>> initialChecks;
  final Map<String, DateRangeValue?> initialDates;
  final String? initialProject;

  const ContactFilterSheet({
    super.key,
    required this.checkGroups,
    this.paginatedGroups = const [],
    required this.initialChecks,
    required this.initialDates,
    required this.initialProject,
  });

  @override
  State<ContactFilterSheet> createState() => _ContactFilterSheetState();
}

class _ContactFilterSheetState extends State<ContactFilterSheet> {
  late Map<String, Set<int>> _stagedChecks;
  late Map<String, DateRangeValue?> _stagedDates;
  late Set<String> _stagedProjects;
  final Map<String, String> _searchQuery = {};
  late final List<_DatePreset> _presets;
  final _fmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _stagedChecks = {
      for (final g in widget.checkGroups)
        g.key: {...(widget.initialChecks[g.key] ?? const <int>{})},
      for (final g in widget.paginatedGroups)
        g.key: {...(widget.initialChecks[g.key] ?? const <int>{})},
    };
    _stagedDates = {...widget.initialDates};
    _stagedProjects = (widget.initialProject ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    for (final g in widget.checkGroups) {
      _searchQuery[g.key] = '';
    }
    _presets = _buildDatePresets();
  }

  List<_DatePreset> _buildDatePresets() {
    final now = AppTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = startOfWeek.subtract(const Duration(days: 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);
    final lastYearStart = DateTime(now.year - 1, now.month, now.day);
    return [
      _DatePreset('Today', today, today),
      _DatePreset('Yesterday', yesterday, yesterday),
      _DatePreset('This Week', startOfWeek, today),
      _DatePreset('Last Week', startOfLastWeek, endOfLastWeek),
      _DatePreset('This Month', startOfMonth, today),
      _DatePreset('Last Month', startOfLastMonth, endOfLastMonth),
      _DatePreset('Last 1 Year', lastYearStart, today),
    ];
  }

  int _activeCount() {
    var n = 0;
    for (final g in widget.checkGroups) {
      if ((_stagedChecks[g.key] ?? const {}).isNotEmpty) n++;
    }
    for (final g in widget.paginatedGroups) {
      if ((_stagedChecks[g.key] ?? const {}).isNotEmpty) n++;
    }
    for (final d in _dateDims) {
      if (_stagedDates[d.key] != null) n++;
    }
    if (_stagedProjects.isNotEmpty) n++;
    return n;
  }

  void _resetStaged() {
    setState(() {
      for (final g in widget.checkGroups) {
        _stagedChecks[g.key] = {};
      }
      for (final g in widget.paginatedGroups) {
        _stagedChecks[g.key] = {};
      }
      for (final d in _dateDims) {
        _stagedDates[d.key] = null;
      }
      _stagedProjects = {};
    });
  }

  ContactFilterResult _buildResult() => ContactFilterResult(
    statusIds: _stagedChecks['status'] ?? const {},
    channelIds: _stagedChecks['channel'] ?? const {},
    channelDetailIds: _stagedChecks['channelDetail'] ?? const {},
    ownerIds: _stagedChecks['owner'] ?? const {},
    executiveIds: _stagedChecks['executive'] ?? const {},
    supervisorIds: _stagedChecks['supervisor'] ?? const {},
    managerIds: _stagedChecks['manager'] ?? const {},
    generalManagerIds: _stagedChecks['gm'] ?? const {},
    teamIds: _stagedChecks['team'] ?? const {},
    createDate: _stagedDates['create'],
    apptDate: _stagedDates['appt'],
    visitDate: _stagedDates['visit'],
    reserveDate: _stagedDates['reserve'],
    spDate: _stagedDates['sp'],
    lostDate: _stagedDates['lost'],
    project: _stagedProjects.isEmpty ? null : _stagedProjects.join(','),
  );

  @override
  Widget build(BuildContext context) {
    final activeCount = _activeCount();
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: Color(grey7Color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 16, 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(grey11Color),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: Color(grey1Color)),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Filter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (activeCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$activeCount filter aktif',
                          style: TextStyle(fontSize: 11, color: Color(primaryColor), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: activeCount > 0 ? _resetStaged : null,
                  style: TextButton.styleFrom(
                    foregroundColor: Color(primaryColor),
                    disabledForegroundColor: Color(grey7Color),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Color(grey10Color)),
          Expanded(
            child: Container(
              color: Color(backgroundColor),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                children: _buildAccordionList(),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(grey10Color))),
              boxShadow: [
                BoxShadow(
                  color: Color(blackColor).withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, _buildResult()),
                    child: Text(
                      activeCount > 0
                          ? 'Terapkan ($activeCount filter)'
                          : 'Terapkan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccordionList() {
    // Data Kontak: grup statis (Status, Sales Channel — sudah dimuat penuh di depan)
    // + grup paginated bersection 'Data Kontak' (Sales Channel Detail) + Project.
    final dataKontak = <Widget>[
      for (final g in widget.checkGroups) _buildCheckAccordion(g),
      for (final g in widget.paginatedGroups.where((g) => g.section == 'Data Kontak')) _buildPaginatedAccordion(g),
      _buildProjectAccordion(),
    ];

    // Sales: semua hierarki (Owner/Executive/Supervisor/Manager/GM/Team) sekarang
    // dedicated endpoint sendiri (paginated + search di server), bukan lagi
    // diturunkan dari data /me profile.
    final sales = <Widget>[
      for (final g in widget.paginatedGroups.where((g) => g.section == 'Sales')) _buildPaginatedAccordion(g),
    ];

    final tanggal = <Widget>[
      for (final d in _dateDims) _buildDateAccordion(d.key, d.label),
    ];

    return [
      _sectionCard('Data Kontak', dataKontak),
      if (sales.isNotEmpty) _sectionCard('Sales', sales),
      _sectionCard('Tanggal', tanggal),
      const SizedBox(height: 8),
    ];
  }

  IconData _checkGroupIcon(String key) {
    switch (key) {
      case 'status':
        return Icons.flag_rounded;
      case 'channel':
        return Icons.hub_rounded;
      case 'channelDetail':
        return Icons.category_rounded;
      case 'owner':
        return Icons.person_rounded;
      case 'executive':
        return Icons.badge_rounded;
      case 'supervisor':
        return Icons.supervisor_account_rounded;
      case 'manager':
        return Icons.manage_accounts_rounded;
      case 'gm':
        return Icons.workspace_premium_rounded;
      case 'team':
        return Icons.groups_rounded;
      default:
        return Icons.filter_list_rounded;
    }
  }

  IconData _dateIcon(String key) {
    switch (key) {
      case 'create':
        return Icons.calendar_month_rounded;
      case 'appt':
        return Icons.event_available_rounded;
      case 'visit':
        return Icons.directions_walk_rounded;
      case 'reserve':
        return Icons.bookmark_added_rounded;
      case 'sp':
        return Icons.assignment_turned_in_rounded;
      case 'lost':
        return Icons.highlight_off_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  }

  IconData _sectionIcon(String section) {
    switch (section) {
      case 'Data Kontak':
        return Icons.contact_page_rounded;
      case 'Sales':
        return Icons.groups_rounded;
      case 'Tanggal':
        return Icons.event_note_rounded;
      default:
        return Icons.filter_list_rounded;
    }
  }

  Widget _sectionCard(String title, List<Widget> children) {
    // RepaintBoundary + border (bukan blurred BoxShadow) supaya expand/collapse
    // accordion di dalamnya tidak memaksa card lain ikut repaint tiap frame —
    // blur shadow yang resize/reposisi tiap frame animasi itu berat terutama
    // di Flutter Web (CanvasKit), makanya animasinya terasa "berat".
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(grey10Color)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Icon(_sectionIcon(title), size: 14, color: Color(primaryColor)),
                    const SizedBox(width: 6),
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Color(grey5Color),
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: Color(grey10Color)),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _accordionTitle(String label, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Color(primaryColor).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: Color(primaryColor)),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _accordion({required Widget title, required List<Widget> children}) {
    // RepaintBoundary di tiap accordion: pas satu accordion expand/collapse,
    // accordion lain di kartu yang sama cuma geser posisi (kontennya sama
    // persis) — dengan layer sendiri, Flutter tinggal pindah layer itu tanpa
    // re-paint isinya, bukan re-rasterize semuanya tiap frame animasi.
    return RepaintBoundary(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(bottom: 4),
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: Color(primaryColor),
          collapsedIconColor: Color(grey5Color),
          backgroundColor: Color(grey11Color).withValues(alpha: 0.5),
          collapsedBackgroundColor: Colors.transparent,
          title: title,
          children: children,
        ),
      ),
    );
  }

  Widget _pillChip({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Color(primaryColor) : Color(whiteColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Color(primaryColor) : Color(grey8Color)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Color(blackColor),
          ),
        ),
      ),
    );
  }

  Widget _clearLink(VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Color(grey5Color),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: const Icon(Icons.clear_rounded, size: 14),
        label: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildCheckAccordion(ContactCheckGroup g) {
    final selected = _stagedChecks[g.key] ?? const <int>{};
    final query = _searchQuery[g.key] ?? '';
    final items = query.isEmpty ? g.items : g.items.where((i) => i.name.toLowerCase().contains(query.toLowerCase())).toList();

    return _accordion(
      title: _accordionTitle(g.label, icon: _checkGroupIcon(g.key)),
      children: [
        if (g.searchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Color(grey11Color),
                hintText: 'Cari ${g.label.toLowerCase()}…',
                hintStyle: TextStyle(fontSize: 13, color: Color(grey5Color)),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(grey5Color)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(grey8Color)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(grey8Color)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(primaryColor), width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery[g.key] = v),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            children: [
              Text(
                '${selected.length} dari ${items.length} dipilih',
                style: TextStyle(fontSize: 11, color: Color(grey5Color)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() {
                  final ids = items.map((e) => e.id).whereType<int>();
                  _stagedChecks[g.key] = {...selected, ...ids};
                }),
                style: TextButton.styleFrom(
                  foregroundColor: Color(primaryColor),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.done_all_rounded, size: 14),
                label: const Text('Pilih Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _stagedChecks[g.key] = {}),
                style: TextButton.styleFrom(
                  foregroundColor: Color(grey5Color),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.clear_rounded, size: 14),
                label: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 22, color: Color(grey7Color)),
                const SizedBox(height: 6),
                Text(
                  'Tidak ditemukan',
                  style: TextStyle(color: Color(grey5Color), fontSize: 12),
                ),
              ],
            ),
          )
        else
          // Dibatasi tinggi + dirender lazy (ListView.builder) supaya grup dengan
          // ratusan item (mis. Sales Channel Detail) tidak membangun semua
          // CheckboxListTile sekaligus saat accordion dibuka — itu yang bikin
          // terasa nge-lag walau datanya sudah ada di memori, bukan lagi manggil API.
          SizedBox(
            height: (items.length * 52.0).clamp(0.0, 320.0),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final id = item.id;
                if (id == null) return const SizedBox.shrink();
                final checked = selected.contains(id);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  child: CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: checked,
                    activeColor: Color(primaryColor),
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: checked ? Color(primaryColor).withValues(alpha: 0.06) : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: checked ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                    subtitle: item.subtitle != null && item.subtitle!.isNotEmpty
                        ? Text(
                            item.subtitle!,
                            style: TextStyle(fontSize: 11, color: Color(grey5Color)),
                          )
                        : null,
                    onChanged: (v) => setState(() {
                      final next = {...selected};
                      if (v == true) {
                        next.add(id);
                      } else {
                        next.remove(id);
                      }
                      _stagedChecks[g.key] = next;
                    }),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildPaginatedAccordion(PaginatedCheckGroup g) {
    return _accordion(
      title: _accordionTitle(g.label, icon: _checkGroupIcon(g.key)),
      children: [
        _PaginatedGroupBody(
          group: g,
          selected: _stagedChecks[g.key] ?? const <int>{},
          onChanged: (next) => setState(() => _stagedChecks[g.key] = next),
        ),
      ],
    );
  }

  Widget _buildProjectAccordion() {
    final current = _stagedProjects;
    return _accordion(
      title: _accordionTitle('Project', icon: Icons.apartment_rounded),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (current.isNotEmpty) _clearLink(() => setState(() => _stagedProjects = {})),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kContactProjectOptions.map((p) {
                  final selected = current.contains(p);
                  return _pillChip(
                    label: p,
                    selected: selected,
                    onTap: () => setState(() {
                      if (selected) {
                        _stagedProjects = {...current}..remove(p);
                      } else {
                        _stagedProjects = {...current, p};
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateAccordion(String key, String label) {
    final current = _stagedDates[key];
    return _accordion(
      title: _accordionTitle(label, icon: _dateIcon(key)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (current != null) _clearLink(() => setState(() => _stagedDates[key] = null)),
              _buildDatePresetChips(key),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePresetChips(String key) {
    final current = _stagedDates[key];
    final isCustom = current != null && !_presets.any((p) => p.label == current.label);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._presets.map((p) {
          final selected = current?.label == p.label;
          return _pillChip(
            label: p.label,
            selected: selected,
            onTap: () => setState(() {
              _stagedDates[key] = selected
                  ? null
                  : DateRangeValue(
                      label: p.label,
                      start: _fmt.format(p.start),
                      end: _fmt.format(p.end),
                    );
            }),
          );
        }),
        _pillChip(
          label: isCustom ? current.label : 'Custom Range',
          selected: isCustom,
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: AppTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Color(primaryColor),
                      onPrimary: Color(whiteColor),
                      onSurface: Color(blackColor),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final label = '${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM yyyy').format(picked.end)}';
              setState(() {
                _stagedDates[key] = DateRangeValue(
                  label: label,
                  start: _fmt.format(picked.start),
                  end: _fmt.format(picked.end),
                );
              });
            }
          },
        ),
      ],
    );
  }
}

/// Isi accordion untuk grup filter yang datanya paginated (server-side search +
/// infinite scroll) — dipakai untuk Sales Channel Detail dan hierarki sales
/// (Owner/Executive/Supervisor/Manager/GM/Team). Beda dari _buildCheckAccordion:
/// tidak ada "Pilih Semua" (nggak semua data ke-load), search men-trigger fetch
/// baru ke server (bukan filter list lokal), dan scroll ke bawah nge-load
/// halaman berikutnya. State dipegang lokal di sini — cuma dispose kalau
/// accordion-nya ditutup (ExpansionTile melepas children saat collapsed), jadi
/// data di-fetch ulang tiap kali accordion dibuka.
class _PaginatedGroupBody extends StatefulWidget {
  final PaginatedCheckGroup group;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  const _PaginatedGroupBody({
    required this.group,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_PaginatedGroupBody> createState() => _PaginatedGroupBodyState();
}

class _PaginatedGroupBodyState extends State<_PaginatedGroupBody> {
  final List<DropdownOption> _items = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage(1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_loading || _loadingMore) return;
    if (_page >= _lastPage) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 150) {
      _loadPage(_page + 1, isLoadMore: true);
    }
  }

  Future<void> _loadPage(int page, {bool isLoadMore = false}) async {
    setState(() {
      isLoadMore ? _loadingMore = true : _loading = true;
      _error = null;
    });
    final result = await widget.group.fetchPage(page: page, search: _search.isEmpty ? null : _search);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _loadingMore = false;
        _error = failure;
      }),
      (data) => setState(() {
        if (isLoadMore) {
          _items.addAll(data.data);
        } else {
          _items
            ..clear()
            ..addAll(data.data);
        }
        _page = page;
        _lastPage = data.lastPage;
        _total = data.total;
        _loading = false;
        _loadingMore = false;
      }),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value;
      _loadPage(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Color(grey11Color),
              hintText: 'Cari ${widget.group.label.toLowerCase()}…',
              hintStyle: TextStyle(fontSize: 13, color: Color(grey5Color)),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(grey5Color)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(grey8Color)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(grey8Color)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(primaryColor), width: 1.5),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            children: [
              Text(
                _loading ? 'Memuat…' : '${widget.selected.length} dipilih dari $_total',
                style: TextStyle(fontSize: 11, color: Color(grey5Color)),
              ),
              const Spacer(),
              if (widget.selected.isNotEmpty)
                TextButton.icon(
                  onPressed: () => widget.onChanged({}),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(grey5Color),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.clear_rounded, size: 14),
                  label: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              children: [
                Icon(Icons.error_outline_rounded, size: 22, color: Color(grey7Color)),
                const SizedBox(height: 6),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Color(grey5Color), fontSize: 12)),
              ],
            ),
          )
        else if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 22, color: Color(grey7Color)),
                const SizedBox(height: 6),
                Text('Tidak ditemukan', style: TextStyle(color: Color(grey5Color), fontSize: 12)),
              ],
            ),
          )
        else
          SizedBox(
            height: (_items.length * 52.0).clamp(0.0, 320.0),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: _items.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                }
                final item = _items[index];
                final checked = widget.selected.contains(item.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  child: CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: checked,
                    activeColor: Color(primaryColor),
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: checked ? Color(primaryColor).withValues(alpha: 0.06) : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      item.name,
                      style: TextStyle(fontSize: 13.5, fontWeight: checked ? FontWeight.w700 : FontWeight.normal),
                    ),
                    subtitle: item.subtitle != null && item.subtitle!.isNotEmpty
                        ? Text(item.subtitle!, style: TextStyle(fontSize: 11, color: Color(grey5Color)))
                        : null,
                    onChanged: (v) {
                      final next = {...widget.selected};
                      if (v == true) {
                        next.add(item.id);
                      } else {
                        next.remove(item.id);
                      }
                      widget.onChanged(next);
                    },
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }
}
