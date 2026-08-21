import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/features/contact/data/models/dropdown/contact_filter_result.dart';

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
  final Map<String, Set<int>> initialChecks;
  final Map<String, DateRangeValue?> initialDates;
  final String? initialProject;

  const ContactFilterSheet({
    super.key,
    required this.checkGroups,
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
  late String? _stagedProject;
  final Map<String, String> _searchQuery = {};
  late final List<_DatePreset> _presets;
  final _fmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _stagedChecks = {
      for (final g in widget.checkGroups)
        g.key: {...(widget.initialChecks[g.key] ?? const <int>{})},
    };
    _stagedDates = {...widget.initialDates};
    _stagedProject = widget.initialProject;
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
    for (final d in _dateDims) {
      if (_stagedDates[d.key] != null) n++;
    }
    if (_stagedProject != null) n++;
    return n;
  }

  void _resetStaged() {
    setState(() {
      for (final g in widget.checkGroups) {
        _stagedChecks[g.key] = {};
      }
      for (final d in _dateDims) {
        _stagedDates[d.key] = null;
      }
      _stagedProject = null;
    });
  }

  ContactFilterResult _buildResult() => ContactFilterResult(
    statusIds: _stagedChecks['status'] ?? const {},
    channelIds: _stagedChecks['channel'] ?? const {},
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
    project: _stagedProject,
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
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Color(grey7Color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 22),
                ),
                const Text(
                  'Filter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: _resetStaged,
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: Color(primaryColor),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Color(grey10Color)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildAccordionList(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
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
        ],
      ),
    );
  }

  List<Widget> _buildAccordionList() {
    final list = <Widget>[];
    String? lastSection;
    for (final g in widget.checkGroups) {
      if (g.section != null && g.section != lastSection) {
        if (lastSection == 'Data Kontak') {
          list.add(Divider(height: 1, color: Color(grey10Color)));
          list.add(_buildProjectAccordion());
        }
        list.add(_sectionLabel(g.section!));
        lastSection = g.section;
      }
      list.add(Divider(height: 1, color: Color(grey10Color)));
      list.add(_buildCheckAccordion(g));
    }
    list.add(Divider(height: 1, color: Color(grey10Color)));
    list.add(_sectionLabel('Tanggal'));
    for (final d in _dateDims) {
      list.add(Divider(height: 1, color: Color(grey10Color)));
      list.add(_buildDateAccordion(d.key, d.label));
    }
    list.add(const SizedBox(height: 8));
    return list;
  }

  Widget _sectionLabel(String text) {
    return Container(
      width: double.infinity,
      color: Color(grey11Color),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Color(grey5Color),
        ),
      ),
    );
  }

  Widget _buildCheckAccordion(ContactCheckGroup g) {
    final selected = _stagedChecks[g.key] ?? const <int>{};
    final query = _searchQuery[g.key] ?? '';
    final items = query.isEmpty ? g.items : g.items.where((i) => i.name.toLowerCase().contains(query.toLowerCase())).toList();

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        selected.isEmpty ? g.label : '${g.label} (${selected.length})',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
      children: [
        if (g.searchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Cari ${g.label.toLowerCase()}…',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery[g.key] = v),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  final ids = items.map((e) => e.id).whereType<int>();
                  _stagedChecks[g.key] = {...selected, ...ids};
                }),
                child: const Text('Pilih Semua'),
              ),
              TextButton(
                onPressed: () => setState(() => _stagedChecks[g.key] = {}),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Tidak ditemukan',
              style: TextStyle(color: Color(grey5Color), fontSize: 12),
            ),
          ),
        ...items.map((item) {
          final id = item.id;
          if (id == null) return const SizedBox.shrink();
          final checked = selected.contains(id);
          return CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: checked,
            title: Text(item.name, style: const TextStyle(fontSize: 13.5)),
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
          );
        }),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildProjectAccordion() {
    final current = _stagedProject;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        current == null ? 'Project' : 'Project: $current',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _stagedProject = null),
                  child: const Text('Hapus'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kContactProjectOptions.map((p) {
                  final selected = current == p;
                  return ChoiceChip(
                    label: Text(p),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _stagedProject = selected ? null : p),
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
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        current == null ? label : '$label: ${current.label}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _stagedDates[key] = null),
                  child: const Text('Hapus'),
                ),
              ),
              _buildDatePresetChips(key),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePresetChips(String key) {
    final current = _stagedDates[key];
    final isCustom =current != null && !_presets.any((p) => p.label == current.label);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._presets.map((p) {
          final selected = current?.label == p.label;
          return ChoiceChip(
            label: Text(p.label),
            selected: selected,
            onSelected: (_) => setState(() {
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
        ChoiceChip(
          label: const Text('Custom Range'),
          selected: isCustom,
          onSelected: (_) async {
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
