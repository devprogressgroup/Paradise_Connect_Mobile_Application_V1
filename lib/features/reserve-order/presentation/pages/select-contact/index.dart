import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';
import 'package:progress_group/core/utils/helpers/status_group_color_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/contact_filter_result.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';
import 'package:progress_group/features/contact/domain/entities/prospect/prospect_status.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_state.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_event.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_state.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_event.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_state.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_event.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_state.dart';
import 'package:progress_group/features/contact/presentation/state/sales_hierarchy/sales_hierarchy_service.dart';
import 'package:progress_group/features/contact/presentation/widgets/contact_filter_sheet.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_list_item.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_detail/reserve_order_detail_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_state.dart';

import '../create/reserve_order_navigation.dart';
class SelectContactForReserveOrderPage extends StatefulWidget {
  const SelectContactForReserveOrderPage({super.key});

  @override
  State<SelectContactForReserveOrderPage> createState() =>
      _SelectContactForReserveOrderPageState();
}

class _SelectContactForReserveOrderPageState extends State<SelectContactForReserveOrderPage> {
  static const _defaultSort = 'created_desc';
  static const _sortOptions = <MapEntry<String, String>>[
    MapEntry('created_desc', 'Dibuat: Terbaru'),
    MapEntry('created_asc', 'Dibuat: Terlama'),
    MapEntry('name_asc', 'Nama: A-Z'),
    MapEntry('name_desc', 'Nama: Z-A'),
  ];

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;

  String _search = '';
  String _sort = _defaultSort;
  Set<int> _statusIds = {};
  Set<int> _channelIds = {};
  Set<int> _ownerIds = {};
  Set<int> _executiveIds = {};
  Set<int> _supervisorIds = {};
  Set<int> _managerIds = {};
  Set<int> _generalManagerIds = {};
  Set<int> _teamIds = {};
  bool _openingFilterSheet = false;

  List<int>? _eligibleStatusIds;

  int? _loadingContactId;

  late ContactBloc _contactBloc;

  /// Tab aktif: `contact` (list contact) atau `reserve` (customer yang sudah punya Reserve Order —
  /// detail RO-nya dipakai buat isi otomatis form RO baru).
  String _tab = 'contact';
  String _reserveSearch = '';
  bool _reserveFetched = false;
  int? _loadingReserveOrderId;
  final _reserveScrollController = ScrollController();

  /// Instance lokal (bukan yang global dari main.dart) supaya search di tab ini tidak menimpa
  /// state halaman List Reserve Order yang ada di bawah halaman ini.
  late final ReserveOrderListCubit _reserveListCubit;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_select_contact');
    _contactBloc = context.read<ContactBloc>();
    _reserveListCubit = ReserveOrderListCubit(
      getReserveOrderListUseCase: context
          .read<ReserveOrderListCubit>()
          .getReserveOrderListUseCase,
    );
    context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
    _scrollController.addListener(_onScroll);
    _reserveScrollController.addListener(_onReserveScroll);
    _loadReserveEligibleContacts();
  }

  void _fetchReserve() {
    _reserveFetched = true;
    _reserveListCubit.fetch(
      search: _reserveSearch.isEmpty ? null : _reserveSearch,
      sort: 'terbaru',
    );
  }

  void _onReserveScroll() {
    if (_reserveScrollController.position.pixels >=
        _reserveScrollController.position.maxScrollExtent - 200) {
      final state = _reserveListCubit.state;
      if (state.status != ReserveOrderListStatus.loading &&
          state.status != ReserveOrderListStatus.loadingMore) {
        _reserveListCubit.loadMore();
      }
    }
  }

  void _switchTab(String tab) {
    if (_tab == tab) return;
    AnalyticsService.logEvent('reserve_order_select_contact_tab_$tab');
    _debounce?.cancel();
    setState(() {
      _tab = tab;
      _searchCtrl.text = tab == 'reserve' ? _reserveSearch : _search;
    });
    if (tab == 'reserve' && !_reserveFetched) _fetchReserve();
  }

  Future<void> _loadReserveEligibleContacts() async {
    final prospectStatusBloc = context.read<ProspectStatusBloc>();
    prospectStatusBloc.add(const FetchProspectStatusesEvent());

    bool ready(ProspectStatusState s) => s.status != ProspectStatusEnum.initial && s.status != ProspectStatusEnum.loading;
    final state = ready(prospectStatusBloc.state)
        ? prospectStatusBloc.state
        : await prospectStatusBloc.stream.firstWhere(ready);
    if (!mounted) return;

    _eligibleStatusIds = state.status == ProspectStatusEnum.loaded
        ? state.statuses
              .where((s) => s.group == 'reserve')
              .map((s) => s.statusProspectId)
              .toList()
        : null;

    _fetch();
  }

  void _fetch() {
    final hasStatusFilter = _statusIds.isNotEmpty;
    final statusIds = hasStatusFilter ? _statusIds.toList() : _eligibleStatusIds;
    _contactBloc.add(
      FetchContactsEvent(
        search: _search.isEmpty ? null : _search,
        clearSearch: _search.isEmpty,
        statusProspectIds: statusIds,
        clearStatus: statusIds == null,
        salesChannelIds: _channelIds.isEmpty ? null : _channelIds.toList(),
        clearSalesChannel: _channelIds.isEmpty,
        ownerIds: _ownerIds.isEmpty ? null : _ownerIds.toList(),
        clearOwner: _ownerIds.isEmpty,
        salesExecutiveIds: _executiveIds.isEmpty ? null : _executiveIds.toList(),
        clearSalesExecutive: _executiveIds.isEmpty,
        salesSupervisorIds: _supervisorIds.isEmpty ? null : _supervisorIds.toList(),
        clearSalesSupervisor: _supervisorIds.isEmpty,
        salesManagerIds: _managerIds.isEmpty ? null : _managerIds.toList(),
        clearSalesManager: _managerIds.isEmpty,
        salesGeneralManagerIds: _generalManagerIds.isEmpty ? null : _generalManagerIds.toList(),
        clearSalesGeneralManager: _generalManagerIds.isEmpty,
        salesTeamIds: _teamIds.isEmpty ? null : _teamIds.toList(),
        clearSalesTeam: _teamIds.isEmpty,
        sort: _sort == _defaultSort ? null : _sort,
        clearSort: _sort == _defaultSort,
        isRefresh: true,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _reserveScrollController.dispose();
    _reserveListCubit.close();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _contactBloc.add(ClearContactsEvent());
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = _contactBloc.state;
      if (state.status != ContactStatus.loading && !state.hasReachedMax) {
        _contactBloc.add(const FetchContactsEvent());
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      AnalyticsService.logEvent('reserve_order_select_contact_search');
      if (_tab == 'reserve') {
        _reserveSearch = value.trim();
        _fetchReserve();
      } else {
        _search = value.trim();
        _fetch();
      }
    });
  }

  int get _activeFilterCount {
    var n = 0;
    if (_statusIds.isNotEmpty) n++;
    if (_channelIds.isNotEmpty) n++;
    if (_ownerIds.isNotEmpty) n++;
    if (_executiveIds.isNotEmpty) n++;
    if (_supervisorIds.isNotEmpty) n++;
    if (_managerIds.isNotEmpty) n++;
    if (_generalManagerIds.isNotEmpty) n++;
    if (_teamIds.isNotEmpty) n++;
    return n;
  }

  Future<T> _waitUntilReady<T>(
    Stream<T> stream,
    bool Function(T) isReady,
    T current,
  ) {
    if (isReady(current)) return Future.value(current);
    return stream.firstWhere(isReady);
  }

  Future<void> _openFilterSheet() async {
    AnalyticsService.logEvent('reserve_order_select_contact_filter');
    final statusBloc = context.read<ProspectStatusBloc>();
    final sourceBloc = context.read<InfoSourceBloc>();

    setState(() => _openingFilterSheet = true);
    await Future.wait([
      _waitUntilReady<ProspectStatusState>(
        statusBloc.stream,
        (s) =>
            s.status != ProspectStatusEnum.initial &&
            s.status != ProspectStatusEnum.loading,
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

    final statusItems = statusBloc.state.statuses
        .where((s) => s.group == 'reserve')
        .map((s) => OwnerDropdownItem(id: s.statusProspectId, name: s.statusProspectName))
        .toList();
    final channelItems = (sourceBloc.state.sourcesMap[1] ?? const <InfoSource>[])
        .map((e) => OwnerDropdownItem(id: e.id, name: e.name))
        .toList();

    final checkGroups = <ContactCheckGroup>[
      ContactCheckGroup(
        key: 'status',
        label: 'Status Prospek',
        section: null,
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

    // Hierarki sales (Owner/Executive/Supervisor/Manager/GM/Team) — sama persis dgn
    // filter di contact-page, dedicated endpoint sendiri-sendiri (paginated + search
    // di server) lewat SalesHierarchyService.
    final hierarchyService = context.read<SalesHierarchyService>();
    final paginatedGroups = <PaginatedCheckGroup>[
      PaginatedCheckGroup(
        key: 'owner',
        label: 'Owner',
        section: 'Sales',
        fetchPage: hierarchyService.owners,
      ),
      PaginatedCheckGroup(
        key: 'executive',
        label: 'Sales Executive',
        section: 'Sales',
        fetchPage: hierarchyService.executives,
      ),
      PaginatedCheckGroup(
        key: 'supervisor',
        label: 'Sales Supervisor',
        section: 'Sales',
        fetchPage: hierarchyService.supervisors,
      ),
      PaginatedCheckGroup(
        key: 'manager',
        label: 'Sales Manager',
        section: 'Sales',
        fetchPage: hierarchyService.managers,
      ),
      PaginatedCheckGroup(
        key: 'gm',
        label: 'General Manager',
        section: 'Sales',
        fetchPage: hierarchyService.generalManagers,
      ),
      PaginatedCheckGroup(
        key: 'team',
        label: 'Sales Team',
        section: 'Sales',
        fetchPage: hierarchyService.teams,
      ),
    ];

    if (!mounted) return;
    final result = await showModalBottomSheet<ContactFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactFilterSheet(
        checkGroups: checkGroups,
        paginatedGroups: paginatedGroups,
        initialChecks: {
          'status': _statusIds,
          'channel': _channelIds,
          'owner': _ownerIds,
          'executive': _executiveIds,
          'supervisor': _supervisorIds,
          'manager': _managerIds,
          'gm': _generalManagerIds,
          'team': _teamIds,
        },
        initialDates: const {},
        initialProject: null,
        showDateSection: false,
        dataSectionTitle: 'Filter',
      ),
    );

    if (result != null) {
      setState(() {
        _statusIds = result.statusIds;
        _channelIds = result.channelIds;
        _ownerIds = result.ownerIds;
        _executiveIds = result.executiveIds;
        _supervisorIds = result.supervisorIds;
        _managerIds = result.managerIds;
        _generalManagerIds = result.generalManagerIds;
        _teamIds = result.teamIds;
      });
      _fetch();
    }
  }

  Future<void> _openSortSheet() async {
    AnalyticsService.logEvent('reserve_order_select_contact_sort');
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
      setState(() => _sort = _sortOptions[selected.id!].key);
      _fetch();
    }
  }

  Future<ContactState> _waitForDetail(ContactBloc bloc) {
    bool ready(ContactState s) =>
        s.status == ContactStatus.detailLoaded ||
        s.status == ContactStatus.error;
    if (ready(bloc.state)) return Future.value(bloc.state);
    return bloc.stream.firstWhere(ready);
  }

  Future<void> _onSelectContact(ContactEntity contact) async {
    final contactId = contact.contactId;
    if (contactId == null || _loadingContactId != null) return;

    setState(() => _loadingContactId = contactId);
    AnalyticsService.logEvent('reserve_order_select_contact_pick');
    try {
      await _openCreateForContact(contactId);
    } finally {
      if (mounted) setState(() => _loadingContactId = null);
    }
  }

  /// Ambil detail Reserve Order untuk dapat `contact_id` + data `customer`-nya, lalu buka wizard
  /// Create lewat alur contact yang sama (sales hierarchy, project, attachment KTP/NPWP diambil
  /// dari contact) dengan data customer RO sebagai isian awal form.
  Future<void> _onSelectReserveOrder(ReserveOrderListItem order) async {
    if (_loadingReserveOrderId != null) return;
    setState(() => _loadingReserveOrderId = order.reserveOrderId);
    AnalyticsService.logEvent('reserve_order_select_reserve_customer_pick');
    try {
      final getDetail = context
          .read<ReserveOrderDetailCubit>()
          .getReserveOrderDetailUseCase;
      final result = await getDetail(order.reserveOrderId);
      if (!mounted) return;

      final detail = result.fold((message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return null;
      }, (d) => d);
      if (detail == null) return;

      final contactId = detail.contactId;
      if (contactId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserve Order ini tidak terhubung ke contact.'),
          ),
        );
        return;
      }

      // Dokumen identitas (KTP/NPWP) yang sudah terupload di RO ini — attachment TTS (bukti
      // bayar) dilewati. Nama tipe diambil dari `required_docs` supaya bisa dicocokkan
      // `navigateToCreateReserveOrder` ('ktp'/'npwp'), sama seperti attachment contact.
      final docNames = {
        for (final d in detail.requiredDocs) d.attachmentTypeId: d.name,
      };
      final reserveDocs = [
        for (final a in detail.attachments)
          if (a.reserveOrderTtsId == null &&
              a.attachmentTypeId != null &&
              docNames[a.attachmentTypeId] != null &&
              (a.attachmentPath ?? '').isNotEmpty)
            ContactAttachment(
              contactAttachmentId: a.contactAttachmentId,
              contactId: contactId,
              attachmentTypeId: a.attachmentTypeId!,
              attachmentUrl: a.attachmentPath!,
              attachmentTypeName: docNames[a.attachmentTypeId]!,
              attachmentNote: '',
              createDatetime: a.createDatetime ?? DateTime.now(),
            ),
      ];

      await _openCreateForContact(
        contactId,
        extraAttachments: reserveDocs,
        initialCustomer: {
          ...detail.customer,
          if (detail.caraBayarId != null) 'cara_bayar_id': detail.caraBayarId,
          if ((detail.caraBayarName ?? '').isNotEmpty)
            'cara_bayar_name': detail.caraBayarName,
        },
      );
    } finally {
      if (mounted) setState(() => _loadingReserveOrderId = null);
    }
  }

  Future<void> _openCreateForContact(
    int contactId, {
    Map<String, dynamic>? initialCustomer,
    List<ContactAttachment> extraAttachments = const [],
  }) async {
    _contactBloc.add(FetchContactDetailEvent(contactId));
    final state = await _waitForDetail(_contactBloc);
    if (!mounted) return;

    final detail = state.contactDetail;
    if (state.status != ContactStatus.detailLoaded || detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Gagal memuat detail contact.'),
        ),
      );
      return;
    }

    final attachmentCubit = context.read<AttachmentCubit>();
    await attachmentCubit.fetch(contactId, detail.dealId);
    if (!mounted) return;

    final attachmentState = attachmentCubit.state;
    // Attachment contact didahulukan; dokumen dari RO sebelumnya jadi cadangan kalau contact
    // belum punya KTP/NPWP (yang dipakai yang pertama cocok).
    final attachments = [
      if (attachmentState is AttachmentLoaded) ...attachmentState.data,
      ...extraAttachments,
    ];

    navigateToCreateReserveOrder(
      context,
      contact: detail,
      attachments: attachments,
      initialCustomer: initialCustomer,
      replace: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Pilih Contact',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Untuk Reserve Order baru',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(grey4Color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      'Contact',
                      _tab == 'contact',
                      () => _switchTab('contact'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tabButton(
                      'Customer Reserve',
                      _tab == 'reserve',
                      () => _switchTab('reserve'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: customSearchField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                hintText: _tab == 'reserve'
                    ? 'Cari nama customer / unit…'
                    : 'Cari nama / no. HP contact…',
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 10),
            if (_tab == 'contact') ...[
              _buildFilterRow(),
              _buildActiveChipsRow(),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: _tab == 'reserve'
                  ? _buildReserveList()
                  : BlocBuilder<ContactBloc, ContactState>(
                builder: (context, state) {
                  if (state.status == ContactStatus.loading &&
                      state.contacts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.contacts.isEmpty) {
                    return const Center(child: Text('Tidak ada data kontak'));
                  }
                  // Simpan entity status LENGKAP (bukan cuma nama) — label & warna chip-nya butuh
                  // statusValue/group, sama persis dgn _buildContactBadges() di contact-page.
                  final statusEntities = {
                    for (final s in context.watch<ProspectStatusBloc>().state.statuses)
                      s.statusProspectId: s,
                  };
                  // channel.name di-split ambil kata sebelum "-" (mis. "FB - Ads" -> "FB") — sama
                  // persis dgn channelLabel di _buildContactBadges().
                  final channelNames = {
                    for (final c in context.watch<InfoSourceBloc>().state.sourcesMap[1] ??
                        const <InfoSource>[])
                      c.id: c.name.split('-').first.trim(),
                  };
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: state.hasReachedMax
                        ? state.contacts.length
                        : state.contacts.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= state.contacts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _contactTile(
                        state.contacts[index],
                        statusEntities: statusEntities,
                        channelNames: channelNames,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Color(primaryColor) : Color(grey11Color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Color(whiteColor) : Color(grey1Color),
          ),
        ),
      ),
    );
  }

  Widget _buildReserveList() {
    return BlocBuilder<ReserveOrderListCubit, ReserveOrderListState>(
      bloc: _reserveListCubit,
      builder: (context, state) {
        if ((state.status == ReserveOrderListStatus.initial ||
                state.status == ReserveOrderListStatus.loading) &&
            state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == ReserveOrderListStatus.error &&
            state.items.isEmpty) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Gagal memuat daftar reserve order.',
            ),
          );
        }
        if (state.items.isEmpty) {
          return const Center(child: Text('Tidak ada customer reserve'));
        }
        final items = state.items.map(ReserveOrderListItem.fromEntity).toList();
        return ListView.separated(
          controller: _reserveScrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: state.hasMore ? items.length + 1 : items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return _reserveTile(items[index]);
          },
        );
      },
    );
  }

  Widget _reserveTile(ReserveOrderListItem order) {
    final isThisLoading = _loadingReserveOrderId == order.reserveOrderId;
    final anyLoading = _loadingReserveOrderId != null;
    final unit = [
      order.unitName,
      order.unitSub,
    ].where((e) => e.isNotEmpty && e != '-').join(' · ');
    return InkWell(
      onTap: anyLoading ? null : () => _onSelectReserveOrder(order),
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isThisLoading ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(whiteColor),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(grey10Color)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(primaryColor).withValues(alpha: 0.1),
                child: Text(
                  getInitials(order.customerName),
                  style: TextStyle(
                    color: Color(primaryColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (unit.isNotEmpty)
                      Text(
                        '🏠 $unit',
                        style: TextStyle(fontSize: 11, color: Color(grey5Color)),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: order.statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (isThisLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
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
              key: const ValueKey('select_contact_sort_button'),
              label: sortLabel,
              isSelected: _sort != _defaultSort,
              onTap: _openSortSheet,
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
                  key: const ValueKey('select_contact_filter_button'),
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
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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

  // Sama pola dgn _buildActiveChipsRow()/_buildActiveChips() di contact-page/index.dart — baris
  // chip filter aktif (bisa di-remove satu-satu) + "Hapus Semua". Beda dari contact-page: label
  // Owner/SE/SPV/SM/GM/Team di sini TIDAK di-resolve ke nama asli (contact-page resolve lewat
  // ProfileBloc/hierarki /me yang tidak dipakai di halaman ini) — cukup label peran generik
  // ("Owner", "2 Sales Executives", dst), sama seperti fallback yang dipakai contact-page saat
  // kandidatnya tidak ketemu.
  void _clearAllFilters() {
    AnalyticsService.logEvent('reserve_order_select_contact_clear_all_filters');
    setState(() {
      _statusIds = {};
      _channelIds = {};
      _ownerIds = {};
      _executiveIds = {};
      _supervisorIds = {};
      _managerIds = {};
      _generalManagerIds = {};
      _teamIds = {};
    });
    _fetch();
  }

  List<MapEntry<String, VoidCallback>> _buildActiveChips() {
    final chips = <MapEntry<String, VoidCallback>>[];

    if (_statusIds.isNotEmpty) {
      final statuses = context
          .watch<ProspectStatusBloc>()
          .state
          .statuses
          .where((s) => s.group == 'reserve');
      String label = 'Status';
      if (_statusIds.length == 1) {
        final st = statuses
            .cast<ProspectStatusEntity?>()
            .firstWhere((s) => s?.statusProspectId == _statusIds.first, orElse: () => null);
        if (st != null) label = st.statusProspectName;
      } else {
        label = '${_statusIds.length} Statuses';
      }
      chips.add(MapEntry(label, () {
        setState(() => _statusIds = {});
        _fetch();
      }));
    }

    if (_channelIds.isNotEmpty) {
      final channels = context.watch<InfoSourceBloc>().state.sourcesMap[1] ?? const <InfoSource>[];
      String label = 'Sales Channel';
      if (_channelIds.length == 1) {
        final found = channels.cast<InfoSource?>().firstWhere((c) => c?.id == _channelIds.first, orElse: () => null);
        if (found != null) label = found.name;
      } else {
        label = '${_channelIds.length} Sales Channels';
      }
      chips.add(MapEntry(label, () {
        setState(() => _channelIds = {});
        _fetch();
      }));
    }

    void addRoleChip(Set<int> ids, String singular, String plural, VoidCallback clear) {
      if (ids.isEmpty) return;
      final label = ids.length == 1 ? singular : '${ids.length} $plural';
      chips.add(MapEntry(label, () {
        setState(clear);
        _fetch();
      }));
    }

    addRoleChip(_ownerIds, 'Owner', 'Owners', () => _ownerIds = {});
    addRoleChip(_executiveIds, 'Sales Executive', 'Sales Executives', () => _executiveIds = {});
    addRoleChip(_supervisorIds, 'Sales Supervisor', 'Sales Supervisors', () => _supervisorIds = {});
    addRoleChip(_managerIds, 'Sales Manager', 'Sales Managers', () => _managerIds = {});
    addRoleChip(_generalManagerIds, 'General Manager', 'General Managers', () => _generalManagerIds = {});
    addRoleChip(_teamIds, 'Sales Team', 'Sales Teams', () => _teamIds = {});

    return chips;
  }

  Widget _buildActiveChipsRow() {
    final chips = _buildActiveChips();
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
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
                child: Text(
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
              style: TextStyle(
                fontSize: 12,
                color: Color(primaryColor),
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Color(primaryColor).withValues(alpha: 0.1),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: chip.value,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  // Sama persis dgn _statusChip()/_channelChip() di contact-page/index.dart (pill berwarna sesuai
  // group status, chip channel border abu-abu) — supaya tampilan status/channel konsisten di
  // seluruh app, bukan cuma teks polos spt _metaChip() sebelumnya.
  Widget _statusChip(String label, {required String group}) {
    final color = statusGroupColor(group);
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _channelChip(String label) {
    const color = Color(grey4Color);
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _contactTile( ContactEntity contact, { required Map<int, ProspectStatusEntity> statusEntities, required Map<int, String> channelNames, }) {
    final project = contact.lastProject ?? contact.firstProject;
    final statusEntity = statusEntities[contact.statusProspectId];
    final statusLabel = statusEntity == null ? null : (statusEntity.statusValue.isNotEmpty ? statusEntity.statusValue : statusEntity.statusProspectName);
    final statusGroup = statusEntity?.group ?? 'db';
    final channelName = channelNames[contact.salesChannelId];
    final isThisLoading = _loadingContactId == contact.contactId;
    final anyLoading = _loadingContactId != null;
    return InkWell(
      onTap: anyLoading ? null : () => _onSelectContact(contact),
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isThisLoading ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(whiteColor),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(grey10Color)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(primaryColor).withValues(alpha: 0.1),
                child: Text(
                  getInitials(contact.fullName ?? '-'),
                  style: TextStyle(
                    color: Color(primaryColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.fullName ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          contact.whatsappNumber ?? contact.primaryPhone ?? 'No Phone',
                          style: TextStyle(fontSize: 12, color: Color(grey5Color)),
                        ),
                        //  Text(
                        //   contact.lastProject ?? contact.firstProject ?? '',
                        //   style: TextStyle(fontSize: 12, color: Color(grey5Color)),
                        // ),
                        if (project != null && project.isNotEmpty)
                          Text(
                            project,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(grey5Color),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                      ],
                    ),
                    if (statusLabel != null || channelName != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (statusLabel != null)
                            _statusChip(statusLabel, group: statusGroup),
                          if (statusLabel != null && channelName != null)
                            const SizedBox(height: 6),
                          if (channelName != null) _channelChip(channelName),
                        ],
                      ),
                  ],
                ),
              ),
              if (isThisLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
