import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/contact_filter_result.dart';
import 'package:progress_group/features/contact/domain/entities/dropdown_option.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_event.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_state.dart';
import 'package:progress_group/features/contact/presentation/state/sales_hierarchy/sales_hierarchy_service.dart';
import 'package:progress_group/features/contact/presentation/widgets/contact_filter_sheet.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_list_item.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_filter_sales_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_list_item_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_status/reserve_status_bloc.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_status/reserve_status_event.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_status/reserve_status_state.dart';

import '../detail/index.dart';
import '../select-contact/index.dart';

/// Menu "Reserve Order" — halaman list transaksi, disambungkan ke `GET /reserve-order/list`
/// lewat [ReserveOrderListCubit] (search, filter status, & sort `terbaru`/`terlama` diteruskan ke
/// server — urut aktivitas terakhir: data terbaru / perubahan terbaru; dimensi filter lain di sheet-nya —
/// channel, owner, dst — belum didukung endpoint-nya).
class ReserveOrderListPage extends StatefulWidget {
  const ReserveOrderListPage({super.key});

  @override
  State<ReserveOrderListPage> createState() => _ReserveOrderListPageState();
}

class _ReserveOrderListPageState extends State<ReserveOrderListPage> {
  static const _defaultSort = 'updated_desc';

  // URUTAN SEPENUHNYA DARI SERVER — app hanya mengirim pilihan (`_serverSort`) & menampilkan hasil apa adanya,
  // TIDAK mengurutkan ulang. Update = aktivitas terakhir RO (data terbaru ATAU perubahan terbaru: dibuat, diubah,
  // Kasir/SA, TTS, status, catatan, milestone) — default; Dibuat = tanggal RO dibuat; Nama = nama customer.
  static const _sortOptions = <MapEntry<String, String>>[
    MapEntry('updated_desc', 'Update: Terbaru'),
    MapEntry('updated_asc', 'Update: Terlama'),
    MapEntry('created_desc', 'Dibuat: Terbaru'),
    MapEntry('created_asc', 'Dibuat: Terlama'),
    MapEntry('name_asc', 'Nama: A-Z'),
    MapEntry('name_desc', 'Nama: Z-A'),
  ];

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;

  String _search = '';
  String _sort = _defaultSort;
  bool _openingFilterSheet = false;

  Set<int> _statusIds = {};
  Set<int> _channelIds = {};
  Set<int> _channelDetailIds = {};
  Set<int> _ownerIds = {};
  Set<int> _executiveIds = {};
  Set<int> _supervisorIds = {};
  Set<int> _managerIds = {};
  Set<int> _gmIds = {};
  Set<int> _teamIds = {};
  String? _project;

  /// Filter "Progres Akad" (tahap setelah SP) & "Persetujuan" — pilihannya dari server (`filter_options`).
  Set<int> _progressIds = {};
  Set<int> _approvalIds = {};

  /// Cache pilihan dropdown Sales (`GET /reserve-order/filter-sales`) — 1 request untuk semua dropdown Sales.
  /// Di-null-kan lagi kalau gagal, jadi buka filter/Coba lagi berikutnya request ulang.
  Future<Either<String, ReserveOrderFilterSalesEntity>>? _salesFuture;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_list');
    context.read<ReserveStatusBloc>().add(const FetchReserveStatusesEvent());
    context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
    _scrollController.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch() {
    return context.read<ReserveOrderListCubit>().fetch(
      search: _search.trim().isEmpty ? null : _search.trim(),
      statusReserveIds: _statusIds.isEmpty ? null : _statusIds.toList(),
      sort: _serverSort,
      salesChannelIds: _channelIds.isEmpty ? null : _channelIds.toList(),
      channelDetailIds: _channelDetailIds.isEmpty ? null : _channelDetailIds.toList(),
      ownerIds: _ownerIds.isEmpty ? null : _ownerIds.toList(),
      salesExecutiveIds: _executiveIds.isEmpty ? null : _executiveIds.toList(),
      salesSupervisorIds: _supervisorIds.isEmpty ? null : _supervisorIds.toList(),
      salesManagerIds: _managerIds.isEmpty ? null : _managerIds.toList(),
      generalManagerIds: _gmIds.isEmpty ? null : _gmIds.toList(),
      salesTeamIds: _teamIds.isEmpty ? null : _teamIds.toList(),
      project: (_project ?? '').isEmpty ? null : _project,
      milestoneIds: _progressIds.isEmpty ? null : _progressIds.toList(),
      approvalIds: _approvalIds.isEmpty ? null : _approvalIds.toList(),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<ReserveOrderListCubit>().state;
      if (state.status != ReserveOrderListStatus.loading &&
          state.status != ReserveOrderListStatus.loadingMore) {
        context.read<ReserveOrderListCubit>().loadMore();
      }
    }
  }

  int get _activeFilterCount {
    var n = 0;
    if (_statusIds.isNotEmpty) n++;
    if (_progressIds.isNotEmpty) n++;
    if (_approvalIds.isNotEmpty) n++;
    if (_channelIds.isNotEmpty) n++;
    if (_channelDetailIds.isNotEmpty) n++;
    if (_ownerIds.isNotEmpty) n++;
    if (_executiveIds.isNotEmpty) n++;
    if (_supervisorIds.isNotEmpty) n++;
    if (_managerIds.isNotEmpty) n++;
    if (_gmIds.isNotEmpty) n++;
    if (_teamIds.isNotEmpty) n++;
    if (_project != null && _project!.isNotEmpty) n++;
    return n;
  }

  /// Pilihan urutan → param `sort` `GET /reserve-order/list`. Semua urutan dikerjakan server.
  String get _serverSort => switch (_sort) {
    'updated_asc' => 'update_terlama',
    'created_desc' => 'dibuat_terbaru',
    'created_asc' => 'dibuat_terlama',
    'name_asc' => 'nama_az',
    'name_desc' => 'nama_za',
    _ => 'update_terbaru',
  };

  /// Item list APA ADANYA sesuai urutan server (tidak diurutkan ulang di app — halaman berikutnya
  /// dari infinite scroll tetap konsisten dgn urutan server).
  List<ReserveOrderListItem> _visibleItems(ReserveOrderListState state) =>
      state.items.map(ReserveOrderListItem.fromEntity).toList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReserveOrderListCubit, ReserveOrderListState>(
      builder: (context, state) {
        final visible = _visibleItems(state);
        return Scaffold(
          backgroundColor: const Color(grey11Color),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: customSearchField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    hintText: 'Cari nama / unit...',
                    onChanged: (value) {
                      AnalyticsService.logEvent('reserve_order_list_search');
                      _search = value;
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 400),
                        _fetch,
                      );
                    },
                  ),
                ),
                _buildFilterRow(),
                // Sama pola dgn halaman Contacts: chip filter aktif (hapus satu²) + "Hapus Semua", lalu total.
                _buildActiveChipsRow(context),
                _buildTotalRow(state),
                Expanded(child: _buildBody(state, visible)),
              ],
            ),
          ),
          floatingActionButton: !PermissionsHelper.canCreateReserveOrder ? null : Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              onPressed: () {
                AnalyticsService.logEvent('reserve_order_list_fab_create');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SelectContactForReserveOrderPage(),
                  ),
                );
              },
              backgroundColor: const Color(primaryColor),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Color(whiteColor)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        border: Border(bottom: BorderSide(color: Color(grey10Color))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reserve Order',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(blue2Color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final sortLabel = _sortOptions.firstWhere((e) => e.key == _sort).value;
    final filterCount = _activeFilterCount;
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CustomFilterButton(
              key: const ValueKey('reserve_order_sort_button'),
              label: sortLabel,
              isSelected: _sort != _defaultSort,
              onTap: _openSortSheet,
              // Hapus urutan → kembali ke default & minta ulang ke server (urutan dari server, bukan app).
              onClear: _sort != _defaultSort
                  ? () {
                      setState(() => _sort = _defaultSort);
                      _fetch();
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                CustomFilterButton(
                  key: const ValueKey('reserve_order_filter_button'),
                  label: 'Filter',
                  isSelected: filterCount > 0,
                  onTap: _openingFilterSheet ? () {} : _openFilterSheet,
                ),
                if (_openingFilterSheet)
                  const Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (filterCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(redColor),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$filterCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(whiteColor),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "Hapus Semua" — kosongkan SEMUA filter sheet (urutan & pencarian tetap), lalu minta ulang ke server.
  void _clearAllFilters() {
    AnalyticsService.logEvent('reserve_order_list_clear_all_filters');
    setState(() {
      _statusIds = {};
      _progressIds = {};
      _approvalIds = {};
      _channelIds = {};
      _channelDetailIds = {};
      _ownerIds = {};
      _executiveIds = {};
      _supervisorIds = {};
      _managerIds = {};
      _gmIds = {};
      _teamIds = {};
      _project = null;
    });
    _fetch();
  }

  /// Chip filter aktif (label → aksi hapus). 1 pilihan → namanya langsung (mis. "SP", "Collect Data",
  /// "⏳ Masih di Kasir"); >1 → "<jumlah> <nama filter>" (mis. "2 Progres Akad"). Urutan SAMA dgn sheet Filter.
  /// Owner/SE/SPV/SM/GM/Team/Channel Detail tidak di-resolve ke nama (datanya paginated di sheet) — cukup nama
  /// filternya, sama seperti fallback halaman Contacts.
  List<MapEntry<String, VoidCallback>> _buildActiveChips(BuildContext context) {
    final chips = <MapEntry<String, VoidCallback>>[];
    final listState = context.watch<ReserveOrderListCubit>().state;
    final statuses = context.watch<ReserveStatusBloc>().state.statuses;
    final channels = context.watch<InfoSourceBloc>().state.sourcesMap[1] ?? const <InfoSource>[];

    void add(
      Set<int> ids,
      String filterName,
      String? Function(int id) nameOf,
      VoidCallback clear,
    ) {
      if (ids.isEmpty) return;
      final label = ids.length == 1 ? (nameOf(ids.first) ?? filterName) : '${ids.length} $filterName';
      chips.add(MapEntry(label, () {
        setState(clear);
        _fetch();
      }));
    }

    String? optionName(List<ReserveOrderFilterOptionEntity> options, int id) =>
        options.where((o) => o.id == id).map((o) => o.name).firstOrNull;

    add(
      _statusIds,
      'Status Reserve',
      (id) => statuses.where((s) => s.statusReserveId == id).map((s) => s.displayName).firstOrNull,
      () => _statusIds = {},
    );
    add(_progressIds, 'Progres Akad', (id) => optionName(listState.progressOptions, id), () => _progressIds = {});
    add(_approvalIds, 'Persetujuan', (id) => optionName(listState.approvalOptions, id), () => _approvalIds = {});
    add(
      _channelIds,
      'Sales Channel',
      (id) => channels.where((c) => c.id == id).map((c) => c.name).firstOrNull,
      () => _channelIds = {},
    );
    add(_channelDetailIds, 'Sales Channel Detail', (_) => null, () => _channelDetailIds = {});
    add(_ownerIds, 'Owner', (_) => null, () => _ownerIds = {});
    add(_executiveIds, 'Sales Executive', (_) => null, () => _executiveIds = {});
    add(_supervisorIds, 'Sales Supervisor', (_) => null, () => _supervisorIds = {});
    add(_managerIds, 'Sales Manager', (_) => null, () => _managerIds = {});
    add(_gmIds, 'General Manager', (_) => null, () => _gmIds = {});
    add(_teamIds, 'Sales Team', (_) => null, () => _teamIds = {});

    if ((_project ?? '').isNotEmpty) {
      chips.add(MapEntry('Project: ${_project!.split(',').map((e) => e.trim()).join(', ')}', () {
        setState(() => _project = null);
        _fetch();
      }));
    }

    return chips;
  }

  /// [context] = context builder BlocBuilder (bukan context State) supaya `watch` sah dipanggil di sini.
  Widget _buildActiveChipsRow(BuildContext context) {
    final chips = _buildActiveChips(context);
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: chips.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            if (i == chips.length) {
              return Center(
                child: TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text(
                    'Hapus Semua',
                    style: TextStyle(
                      color: Color(redColor),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }
            final chip = chips[i];
            return Chip(
              label: Text(
                chip.key,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(primaryColor),
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(primaryColor).withValues(alpha: 0.1),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: chip.value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            );
          },
        ),
      ),
    );
  }

  /// "Total: N reserve order" (total dari server, sesuai filter & pencarian) — sama dgn "Total: N contacts".
  Widget _buildTotalRow(ReserveOrderListState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Total: ${NumberHelper.thousands(state.total)} reserve order',
          style: const TextStyle(
            fontSize: 13,
            color: Color(grey5Color),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _openSortSheet() async {
    AnalyticsService.logEvent('reserve_order_list_sort');
    final selectedIndex = _sortOptions.indexWhere((e) => e.key == _sort);
    final items = List.generate(
      _sortOptions.length,
      (i) => OwnerDropdownItem(id: i, name: _sortOptions[i].value),
    );

    final result = await context.pushNamed(
      'detailContactDropdown',
      extra: ContactDropdownArgs(
        title: 'Urutkan',
        items: items,
        selectedId: selectedIndex >= 0 ? selectedIndex : 0,
        isMultiSelect: false,
        allowClear: _sort != _defaultSort,
        preserveOrder: true,
      ),
    );

    if (result is List) {
      if (mounted) setState(() => _sort = _defaultSort);
      _fetch();
      return;
    }
    if (result != null && mounted) {
      final selected = result as OwnerDropdownItem;
      final newSort = _sortOptions[selected.id!].key;
      if (newSort == _sort) return;
      setState(() => _sort = newSort);
      _fetch(); // semua urutan dari server
    }
  }

  Future<T> _waitUntilReady<T>(
    Stream<T> stream,
    bool Function(T) isReady,
    T current,
  ) {
    if (isReady(current)) return Future.value(current);
    return stream
        .firstWhere(isReady)
        .timeout(const Duration(seconds: 6), onTimeout: () => current);
  }

  Future<Either<String, ReserveOrderFilterSalesEntity>> _ensureSales() {
    return _salesFuture ??= _requestSales();
  }

  Future<Either<String, ReserveOrderFilterSalesEntity>> _requestSales() async {
    final cubit = context.read<ReserveOrderListCubit>();
    final result = await cubit.fetchFilterSales();
    if (result.isLeft()) _salesFuture = null;
    return result;
  }

  /// Grup dropdown Sales dari cache `filter-sales`. Datanya sudah lengkap (tidak paginasi), jadi search
  /// dikerjakan lokal dan satu halaman saja.
  PaginatedCheckGroup _salesGroup({
    required String key,
    required String label,
    required List<DropdownOption> Function(ReserveOrderFilterSalesEntity) pick,
  }) {
    return PaginatedCheckGroup(
      key: key,
      label: label,
      section: 'Sales',
      retryable: true,
      fetchPage: ({required int page, int perPage = 20, String? search}) async {
        final result = await _ensureSales();
        return result.fold<Either<String, ({List<DropdownOption> data, int lastPage, int total})>>(
          (_) => const Left('Gagal memuat pilihan'),
          (data) {
            final all = pick(data);
            final q = (search ?? '').trim().toLowerCase();
            final filtered = q.isEmpty
                ? all
                : all.where((o) => o.name.toLowerCase().contains(q)).toList();
            return Right((data: filtered, lastPage: 1, total: filtered.length));
          },
        );
      },
    );
  }

  Future<void> _openFilterSheet() async {
    AnalyticsService.logEvent('reserve_order_list_filter');
    _ensureSales(); // mulai ambil pilihan Sales sekarang; accordion Sales menunggu hasilnya
    final statusBloc = context.read<ReserveStatusBloc>();
    final sourceBloc = context.read<InfoSourceBloc>();

    setState(() => _openingFilterSheet = true);
    await Future.wait([
      _waitUntilReady<ReserveStatusState>(
        statusBloc.stream,
        (s) =>
            s.status != ReserveStatusEnum.initial &&
            s.status != ReserveStatusEnum.loading,
        statusBloc.state,
      ),
      _waitUntilReady<InfoSourceState>(
        sourceBloc.stream,
        (s) =>
            s.status != InfoSourceStatus.initial &&
            s.status != InfoSourceStatus.loading,
        sourceBloc.state,
      ),
    ]);
    if (!mounted) return;
    setState(() => _openingFilterSheet = false);

    final statusState = statusBloc.state;
    final sourceState = sourceBloc.state;

    final statusItems = statusState.status == ReserveStatusEnum.loaded
        ? statusState.statuses
              .map(
                (e) => OwnerDropdownItem(
                  id: e.statusReserveId,
                  name: e.displayName,
                ),
              )
              .toList()
        : <OwnerDropdownItem>[];
    final channelItems = (sourceState.sourcesMap[1] ?? const <InfoSource>[])
        .map((e) => OwnerDropdownItem(id: e.id, name: e.name))
        .toList();

    // Pilihan Progres Akad & Persetujuan dari server (`filter_options` response list) — tampil apa adanya.
    // Nama sengaja bahasa sales sehari-hari (dibaca user gaptek), ikon Persetujuan SAMA dgn baris di kartu.
    final listState = context.read<ReserveOrderListCubit>().state;
    OwnerDropdownItem toItem(ReserveOrderFilterOptionEntity e) =>
        OwnerDropdownItem(id: e.id, name: e.name, subtitle: e.subtitle);

    final checkGroups = <ContactCheckGroup>[
      ContactCheckGroup(
        key: 'status',
        label: 'Status Reserve',
        section: 'Data Reserve',
        searchable: true,
        items: statusItems,
      ),
      if (listState.progressOptions.isNotEmpty)
        ContactCheckGroup(
          key: 'progressAkad',
          label: 'Progres Akad',
          section: 'Data Reserve',
          searchable: false,
          items: listState.progressOptions.map(toItem).toList(),
        ),
      if (listState.approvalOptions.isNotEmpty)
        ContactCheckGroup(
          key: 'approval',
          label: 'Persetujuan',
          section: 'Data Reserve',
          searchable: false,
          items: listState.approvalOptions.map(toItem).toList(),
        ),
      ContactCheckGroup(
        key: 'channel',
        label: 'Sales Channel',
        section: null,
        searchable: false,
        items: channelItems,
      ),
    ];

    final hierarchyService = context.read<SalesHierarchyService>();
    final paginatedGroups = <PaginatedCheckGroup>[
      PaginatedCheckGroup(
        key: 'channelDetail',
        label: 'Sales Channel Detail',
        section: 'Data Reserve',
        fetchPage: hierarchyService.channelDetail,
      ),
      _salesGroup(key: 'owner', label: 'Owner', pick: (d) => d.owner),
      _salesGroup(key: 'executive', label: 'Sales Executive', pick: (d) => d.salesExecutive),
      _salesGroup(key: 'supervisor', label: 'Sales Supervisor', pick: (d) => d.salesSupervisor),
      _salesGroup(key: 'manager', label: 'Sales Manager', pick: (d) => d.salesManager),
      _salesGroup(key: 'gm', label: 'General Manager', pick: (d) => d.generalManager),
      _salesGroup(key: 'team', label: 'Sales Team', pick: (d) => d.salesTeam),
    ];

    final initialChecks = <String, Set<int>>{
      'status': _statusIds,
      'progressAkad': _progressIds,
      'approval': _approvalIds,
      'channel': _channelIds,
      'channelDetail': _channelDetailIds,
      'owner': _ownerIds,
      'executive': _executiveIds,
      'supervisor': _supervisorIds,
      'manager': _managerIds,
      'gm': _gmIds,
      'team': _teamIds,
    };

    if (!mounted) return;
    final result = await showModalBottomSheet<ContactFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactFilterSheet(
        checkGroups: checkGroups,
        paginatedGroups: paginatedGroups,
        initialChecks: initialChecks,
        initialDates: const {},
        initialProject: _project,
        showDateSection: false,
        dataSectionTitle: 'Data Reserve',
      ),
    );

    if (result != null) {
      setState(() {
        _statusIds = result.statusIds;
        _progressIds = result.checks['progressAkad'] ?? {};
        _approvalIds = result.checks['approval'] ?? {};
        _channelIds = result.channelIds;
        _channelDetailIds = result.channelDetailIds;
        _ownerIds = result.ownerIds;
        _executiveIds = result.executiveIds;
        _supervisorIds = result.supervisorIds;
        _managerIds = result.managerIds;
        _gmIds = result.generalManagerIds;
        _teamIds = result.teamIds;
        _project = result.project;
      });
      _fetch();
    }
  }

  Widget _buildBody(ReserveOrderListState state, List<ReserveOrderListItem> items) {
    if (state.status == ReserveOrderListStatus.loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ReserveOrderListStatus.error && items.isEmpty) {
      return _refreshableMessage(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage ?? 'Gagal memuat daftar reserve order.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(grey4Color)),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: _fetch, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return _refreshableMessage(
        const Text(
          'Tidak ada Reserve Order yang cocok dengan pencarian/filter.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(grey4Color)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.separated(
        controller: _scrollController,
        // Wajib supaya tarik-refresh tetap jalan walau item-nya sedikit (belum bisa di-scroll).
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _buildCard(items[index]);
        },
      ),
    );
  }

  /// Pesan kosong/error yang tetap bisa ditarik untuk refresh.
  Widget _refreshableMessage(Widget child) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ReserveOrderListItem order) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        AnalyticsService.logEvent('reserve_order_list_open_detail');
        // Detail bisa balik `true` kalau reserve order-nya baru saja dihapus (hard delete) —
        // refresh list-nya biar baris yang sudah tidak ada di server ikut hilang dari layar.
        final deleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                ReserveOrderDetailPage(reserveOrderId: order.reserveOrderId),
          ),
        );
        if (deleted == true) _fetch();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(blackColor).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(blue2Color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status + milestone terakhir yg aktif (tahap setelah SP, mis. "Siap Akad") di bawahnya —
                // sama dgn badge di web (kartu profil & kolom Status grid).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    
                    if (order.milestoneLabel != null) ...[
                      _milestoneBadge(order.milestoneLabel!),
                      const SizedBox(width: 6),

                    ],
                    _statusBadge(order.status, order.statusColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏠', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: order.unitName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(blue2Color),
                      ),
                      children: [
                        TextSpan(
                          text: '\n${order.unitSub}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(grey4Color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _meta('👤', order.salesName),
                _meta('💰', 'Rp ${NumberHelper.thousands(order.amount)}'),
                _meta('💼', order.category),
                
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _meta('📅', order.dateLabel),
                // Status approval dari server: "Kasir ✅ · SA ⏳" / "Kasir ❌" (SA tampil setelah Kasir menyetujui).
                if (order.kasirApproval != null)
                  _approvalLine(order.kasirApproval!, order.saApproval),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// `approved` ✅ / `rejected` ❌ / selain itu (pending) ⏳ — status dihitung server, app hanya menampilkan.
  String _approvalIcon(String state) => switch (state) {
    'approved' => '✅',
    'rejected' => '❌',
    _ => '⏳',
  };

  Widget _approvalLine(String kasir, String? sa) {
    final text = sa == null
        ? 'Kasir  ${_approvalIcon(kasir)}'
        : 'Kasir  ${_approvalIcon(kasir)}  ·  SA  ${_approvalIcon(sa)}';
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: Color(grey4Color),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(whiteColor),
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Badge milestone (tahap setelah SP) — hijau muda + garis, beda dari badge status yg berwarna penuh.
  Widget _milestoneBadge(String label) {
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(successColor).withValues(alpha: 0.12),
        border: Border.all(color: const Color(successColor).withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        
          Text(
            label,
            style: const TextStyle(
              color: Color(successColor),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 10.5)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10.5, color: Color(grey4Color)),
        ),
      ],
    );
  }
}
