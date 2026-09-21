import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/contact_filter_result.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';
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
import 'package:progress_group/features/contact/presentation/widgets/contact_filter_sheet.dart';

import '../create/reserve_order_navigation.dart';

/// Halaman pilih Contact sebelum masuk ke wizard Create Reserve Order — dibuka dari FAB list
/// Reserve Order (yang sebelumnya langsung ke `CreateReserveOrderPage` tanpa contact/data
/// dummy). Setelah Contact dipilih, detail lengkap + attachment-nya di-fetch dulu supaya wizard
/// bisa diisi default data yang sama seperti kalau dibuka dari tombol "Reserve Order" di Contact
/// Detail (lihat `navigateToCreateReserveOrder`).
class SelectContactForReserveOrderPage extends StatefulWidget {
  const SelectContactForReserveOrderPage({super.key});

  @override
  State<SelectContactForReserveOrderPage> createState() =>
      _SelectContactForReserveOrderPageState();
}

class _SelectContactForReserveOrderPageState
    extends State<SelectContactForReserveOrderPage> {
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
  bool _openingFilterSheet = false;

  /// Semua status_prospect_id yang eligible utk Reserve Order (group 'reserve') — dipakai
  /// sebagai fallback filter server saat user belum pilih status spesifik di sheet Filter, DAN
  /// sebagai daftar opsi yang ditawarkan di sheet itu (user cuma boleh mempersempit di dalam
  /// grup ini, bukan keluar darinya).
  List<int>? _eligibleStatusIds;

  /// contactId yang sedang diproses (fetch detail + attachment sebelum masuk wizard Create) —
  /// dilacak per-kontak (bukan boolean tunggal) supaya cuma BARIS yang di-tap yang menampilkan
  /// spinner, bukan seluruh list ikut redup/loading.
  int? _loadingContactId;

  late ContactBloc _contactBloc;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_select_contact');
    _contactBloc = context.read<ContactBloc>();
    context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
    _scrollController.addListener(_onScroll);
    _loadReserveEligibleContacts();
  }

  /// Contact yang boleh dipilih utk Reserve Order dibatasi ke yang status prospek-nya sudah masuk
  /// grup "reserve" (m_prospect_status.group_name = 'reserve' — Reserved/RBB/RBA/dst, sumber
  /// SalesController::getStatusDropdown()). Cuma resolve daftar ID grup itu sekali di sini lalu
  /// simpan ke [_eligibleStatusIds] — [_fetch] yang menyertakannya (atau subset-nya) di SETIAP
  /// request berikutnya, lihat komentar di sana.
  Future<void> _loadReserveEligibleContacts() async {
    final prospectStatusBloc = context.read<ProspectStatusBloc>();
    prospectStatusBloc.add(const FetchProspectStatusesEvent());

    bool ready(ProspectStatusState s) =>
        s.status != ProspectStatusEnum.initial &&
        s.status != ProspectStatusEnum.loading;
    final state = ready(prospectStatusBloc.state)
        ? prospectStatusBloc.state
        : await prospectStatusBloc.stream.firstWhere(ready);
    if (!mounted) return;

    // Gagal muat daftar status → fallback tampilkan semua contact drpd halaman kelihatan kosong
    // padahal cuma error jaringan, bukan memang tidak ada contact yang eligible.
    _eligibleStatusIds = state.status == ProspectStatusEnum.loaded
        ? state.statuses
              .where((s) => s.group == 'reserve')
              .map((s) => s.statusProspectId)
              .toList()
        : null;

    _fetch();
  }

  /// Refetch dari halaman 1 dengan search/status/channel/sort yang sedang aktif — dipanggil ulang
  /// tiap kali salah satu dari filter tsb berubah. `statusProspectIds` SELALU dibatasi ke
  /// `_eligibleStatusIds` (grup "reserve") kalau user belum mempersempit lewat sheet Filter —
  /// constraint ini tidak boleh lepas hanya karena filter lain diganti.
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
      _search = value.trim();
      _fetch();
    });
  }

  int get _activeFilterCount {
    var n = 0;
    if (_statusIds.isNotEmpty) n++;
    if (_channelIds.isNotEmpty) n++;
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

    // Opsi Status Prospek dibatasi ke grup "reserve" — sesuai constraint eligibility halaman ini.
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

    if (!mounted) return;
    final result = await showModalBottomSheet<ContactFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactFilterSheet(
        checkGroups: checkGroups,
        initialChecks: {'status': _statusIds, 'channel': _channelIds},
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
      final attachments = attachmentState is AttachmentLoaded
          ? attachmentState.data
          : const <ContactAttachment>[];

      navigateToCreateReserveOrder(
        context,
        contact: detail,
        attachments: attachments,
        replace: true,
      );
    } finally {
      if (mounted) setState(() => _loadingContactId = null);
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: customSearchField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                hintText: 'Cari nama / no. HP contact…',
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 10),
            _buildFilterRow(),
            const SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<ContactBloc, ContactState>(
                builder: (context, state) {
                  if (state.status == ContactStatus.loading &&
                      state.contacts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.contacts.isEmpty) {
                    return const Center(child: Text('Tidak ada data kontak'));
                  }
                  final statusNames = {
                    for (final s in context.watch<ProspectStatusBloc>().state.statuses)
                      s.statusProspectId: s.statusProspectName,
                  };
                  final channelNames = {
                    for (final c in context.watch<InfoSourceBloc>().state.sourcesMap[1] ??
                        const <InfoSource>[])
                      c.id: c.name,
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
                        statusNames: statusNames,
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

  Widget _metaChip(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 10.5)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 10.5, color: Color(grey5Color)),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _contactTile(
    ContactEntity contact, {
    required Map<int, String> statusNames,
    required Map<int, String> channelNames,
  }) {
    final project = contact.lastProject ?? contact.firstProject;
    final statusName = statusNames[contact.statusProspectId];
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
                child: Column(
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
                      contact.whatsappNumber ??
                          contact.primaryPhone ??
                          'No Phone',
                      style: TextStyle(fontSize: 12, color: Color(grey5Color)),
                    ),
                    if (project != null && project.isNotEmpty)
                      Text(
                        project,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(grey5Color),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (statusName != null || channelName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          children: [
                            if (statusName != null) _metaChip('🏷️', statusName),
                            if (channelName != null) _metaChip('📡', channelName),
                          ],
                        ),
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
