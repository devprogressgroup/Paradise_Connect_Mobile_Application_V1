import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/contact_filter_result.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_event.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_state.dart';
import 'package:progress_group/features/contact/presentation/state/sales_hierarchy/sales_hierarchy_service.dart';
import 'package:progress_group/features/contact/presentation/widgets/contact_filter_sheet.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_list_dummy_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_list_item.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_status/reserve_status_bloc.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_status/reserve_status_event.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_status/reserve_status_state.dart';

import '../create/index.dart';
import '../detail/index.dart';

/// Menu "Reserve Order" — halaman list transaksi.
///
/// Catatan: sementara masih pakai data contoh ([ReserveOrderListDummyDataSource]), belum
/// disambungkan ke API asli. Struktur & data mengikuti prototype `reserve-order-prototype (1).html`
/// (bagian LIST) biar gampang disambung ke datasource sungguhan nanti. Filter/sort sheet-nya
/// sudah dibuat sama seperti punya Contact (lihat [ContactFilterSheet] & rute
/// `detailContactDropdown`) supaya kalau list-nya nanti disambung ke API asli, UI filternya
/// tidak perlu dibongkar lagi.
class ReserveOrderListPage extends StatefulWidget {
  const ReserveOrderListPage({super.key});

  @override
  State<ReserveOrderListPage> createState() => _ReserveOrderListPageState();
}

class _ReserveOrderListPageState extends State<ReserveOrderListPage> {
  static const _defaultSort = 'created_desc';

  static const _sortOptions = <MapEntry<String, String>>[
    MapEntry('created_desc', 'Dibuat: Terbaru'),
    MapEntry('created_asc', 'Dibuat: Terlama'),
    MapEntry('name_asc', 'Nama: A-Z'),
    MapEntry('name_desc', 'Nama: Z-A'),
  ];

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  final _items = const ReserveOrderListDummyDataSource().getAll();

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

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_list');
    context.read<ReserveStatusBloc>().add(const FetchReserveStatusesEvent());
    context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    var n = 0;
    if (_statusIds.isNotEmpty) n++;
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

  List<ReserveOrderListItem> get _visibleItems {
    final term = _search.trim().toLowerCase();

    // Data list-nya masih dummy (belum ada field channel/owner/dst di [ReserveOrderListItem]),
    // jadi baru dimensi status yang benar-benar menyaring hasil — dimensi lain tetap bisa
    // dipilih di sheet-nya tapi menunggu list-nya disambung ke API asli untuk ikut menyaring.
    final statusNames = _statusIds.isEmpty
        ? const <String>{}
        : context
            .read<ReserveStatusBloc>()
            .state
            .statuses
            .where((e) => _statusIds.contains(e.statusReserveId))
            .map((e) => e.displayName)
            .toSet();

    final list = _items.where((o) {
      final matchTerm = term.isEmpty ||
          o.customerName.toLowerCase().contains(term) ||
          o.unitName.toLowerCase().contains(term);
      final matchStatus = statusNames.isEmpty || statusNames.contains(o.status);
      return matchTerm && matchStatus;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case 'created_asc':
          return a.createdAt.compareTo(b.createdAt);
        case 'name_asc':
          return a.customerName.compareTo(b.customerName);
        case 'name_desc':
          return b.customerName.compareTo(a.customerName);
        case 'created_desc':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;
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
                  setState(() => _search = value);
                },
              ),
            ),
            _buildFilterRow(),
            Expanded(child: _buildBody(visible)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          onPressed: () {
            AnalyticsService.logEvent('reserve_order_list_fab_create');
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateReserveOrderPage()),
            );
          },
          backgroundColor: const Color(primaryColor),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Color(whiteColor)),
        ),
      ),
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(blue2Color)),
          ),
          const SizedBox(height: 2),
          Text(
            '${_items.length} transaksi aktif',
            style: const TextStyle(fontSize: 11, color: Color(grey4Color)),
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
              onClear: _sort != _defaultSort ? () => setState(() => _sort = _defaultSort) : null,
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
                      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                if (filterCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(color: Color(redColor), shape: BoxShape.circle),
                      child: Text(
                        '$filterCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(whiteColor), fontSize: 9, fontWeight: FontWeight.bold),
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
      return;
    }
    if (result != null && mounted) {
      final selected = result as OwnerDropdownItem;
      setState(() => _sort = _sortOptions[selected.id!].key);
    }
  }

  Future<T> _waitUntilReady<T>(Stream<T> stream, bool Function(T) isReady, T current) {
    if (isReady(current)) return Future.value(current);
    return stream.firstWhere(isReady).timeout(const Duration(seconds: 6), onTimeout: () => current);
  }

  Future<void> _openFilterSheet() async {
    AnalyticsService.logEvent('reserve_order_list_filter');
    final statusBloc = context.read<ReserveStatusBloc>();
    final sourceBloc = context.read<InfoSourceBloc>();

    setState(() => _openingFilterSheet = true);
    await Future.wait([
      _waitUntilReady<ReserveStatusState>(
        statusBloc.stream,
        (s) => s.status != ReserveStatusEnum.initial && s.status != ReserveStatusEnum.loading,
        statusBloc.state,
      ),
      _waitUntilReady<InfoSourceState>(
        sourceBloc.stream,
        (s) => s.status != InfoSourceStatus.initial && s.status != InfoSourceStatus.loading,
        sourceBloc.state,
      ),
    ]);
    if (!mounted) return;
    setState(() => _openingFilterSheet = false);

    final statusState = statusBloc.state;
    final sourceState = sourceBloc.state;

    final statusItems = statusState.status == ReserveStatusEnum.loaded
        ? statusState.statuses
            .map((e) => OwnerDropdownItem(id: e.statusReserveId, name: e.displayName))
            .toList()
        : <OwnerDropdownItem>[];
    final channelItems = (sourceState.sourcesMap[1] ?? const <InfoSource>[])
        .map((e) => OwnerDropdownItem(id: e.id, name: e.name))
        .toList();

    final checkGroups = <ContactCheckGroup>[
      ContactCheckGroup(
        key: 'status',
        label: 'Status Reserve',
        section: 'Data Reserve',
        searchable: true,
        items: statusItems,
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
      PaginatedCheckGroup(key: 'owner', label: 'Owner', section: 'Sales', fetchPage: hierarchyService.owners),
      PaginatedCheckGroup(key: 'executive', label: 'Sales Executive', section: 'Sales', fetchPage: hierarchyService.executives),
      PaginatedCheckGroup(key: 'supervisor', label: 'Sales Supervisor', section: 'Sales', fetchPage: hierarchyService.supervisors),
      PaginatedCheckGroup(key: 'manager', label: 'Sales Manager', section: 'Sales', fetchPage: hierarchyService.managers),
      PaginatedCheckGroup(key: 'gm', label: 'General Manager', section: 'Sales', fetchPage: hierarchyService.generalManagers),
      PaginatedCheckGroup(key: 'team', label: 'Sales Team', section: 'Sales', fetchPage: hierarchyService.teams),
    ];

    final initialChecks = <String, Set<int>>{
      'status': _statusIds,
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
    }
  }

  Widget _buildBody(List<ReserveOrderListItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Tidak ada Reserve Order yang cocok dengan pencarian/filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(grey4Color)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildCard(items[index]),
    );
  }

  Widget _buildCard(ReserveOrderListItem order) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        AnalyticsService.logEvent('reserve_order_list_open_detail');
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReserveOrderDetailPage(initiallyRejected: order.status == 'Ditolak')),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: const Color(blackColor).withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(order.status, order.statusColor),
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
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(blue2Color)),
                      children: [
                        TextSpan(
                          text: '\n${order.unitSub}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(grey4Color)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _meta('👤', order.salesName),
                _meta('💰', 'Rp ${NumberHelper.thousands(order.amount)}'),
                _meta('💼', order.category),
                _meta('📅', order.dateLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: const TextStyle(color: Color(whiteColor), fontSize: 10.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _meta(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 10.5)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10.5, color: Color(grey4Color))),
      ],
    );
  }
}
