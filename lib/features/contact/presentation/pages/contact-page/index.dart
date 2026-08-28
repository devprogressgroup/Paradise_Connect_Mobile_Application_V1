import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/utils/share_helper.dart';
import 'package:progress_group/core/utils/widget/custom_bg_icon.dart';
import 'package:progress_group/core/constants/colors.dart';

import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';
import 'package:progress_group/core/utils/helpers/status_group_color_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/auth/domain/entities/user_profile.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import '../../../../../core/utils/widget/custom_buttomsheet.dart';
import '../../state/contact/contact_bloc.dart';
import '../../state/contact/contact_event.dart';
import '../../state/contact/contact_state.dart';
import '../../state/prospect_status/prospect_status_bloc.dart';
import '../../state/prospect_status/prospect_status_event.dart';
import '../../state/prospect_status/prospect_status_state.dart';
import '../../state/info_source/info_source_bloc.dart';
import '../../state/info_source/info_source_event.dart';
import '../../state/info_source/info_source_state.dart';
import '../../state/sales_hierarchy/sales_hierarchy_service.dart';
import '../../../domain/entities/info_source/info_source.dart';
import '../../../../../core/utils/widget/custom_filter_button.dart';
import '../../../../../core/utils/widget/error_dialog.dart';
import '../../../domain/entities/prospect/prospect_status.dart';
import '../../widgets/contact_filter_sheet.dart';
import '../../../data/models/dropdown/contact_filter_result.dart';

class ContactPage extends StatefulWidget {
  final List<int>? initialStatusIds;
  final List<int>? initialSalesChannelIds;
  final String? initialStartDate;
  final String? initialEndDate;
  final String? initialApptStartDate;
  final String? initialApptEndDate;
  final String? initialVisitStartDate;
  final String? initialVisitEndDate;
  final String? initialReserveStartDate;
  final String? initialReserveEndDate;
  final String? initialSpStartDate;
  final String? initialSpEndDate;
  final String? initialLostStartDate;
  final String? initialLostEndDate;
  const ContactPage({
    super.key,
    this.initialStatusIds,
    this.initialSalesChannelIds,
    this.initialStartDate,
    this.initialEndDate,
    this.initialApptStartDate,
    this.initialApptEndDate,
    this.initialVisitStartDate,
    this.initialVisitEndDate,
    this.initialReserveStartDate,
    this.initialReserveEndDate,
    this.initialSpStartDate,
    this.initialSpEndDate,
    this.initialLostStartDate,
    this.initialLostEndDate,
  });

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late ScrollController _scrollController;
  Timer? _debounce;
  String? selectedDateLabel;
  String? selectedApptDateLabel;
  String? selectedVisitDateLabel;
  String? selectedReserveDateLabel;
  String? selectedSpDateLabel;
  String? selectedLostDateLabel;
  bool _openingFilterSheet = false;

  List<ContactEntity> contactEntity = [];
  late ContactBloc _contactBloc;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('contact_list');
    _contactBloc = context.read<ContactBloc>();

    _searchController.clear();

    _scrollController = ScrollController()..addListener(_onScroll);

    if (widget.initialStartDate != null) {
      selectedDateLabel = _resolveDateLabel(
        widget.initialStartDate!,
        widget.initialEndDate ?? widget.initialStartDate!,
      );
    }
    if (widget.initialApptStartDate != null) {
      selectedApptDateLabel = _resolveDateLabel(
        widget.initialApptStartDate!,
        widget.initialApptEndDate ?? widget.initialApptStartDate!,
      );
    }
    if (widget.initialVisitStartDate != null) {
      selectedVisitDateLabel = _resolveDateLabel(
        widget.initialVisitStartDate!,
        widget.initialVisitEndDate ?? widget.initialVisitStartDate!,
      );
    }
    if (widget.initialReserveStartDate != null) {
      selectedReserveDateLabel = _resolveDateLabel(
        widget.initialReserveStartDate!,
        widget.initialReserveEndDate ?? widget.initialReserveStartDate!,
      );
    }
    if (widget.initialSpStartDate != null) {
      selectedSpDateLabel = _resolveDateLabel(
        widget.initialSpStartDate!,
        widget.initialSpEndDate ?? widget.initialSpStartDate!,
      );
    }
    if (widget.initialLostStartDate != null) {
      selectedLostDateLabel = _resolveDateLabel(
        widget.initialLostStartDate!,
        widget.initialLostEndDate ?? widget.initialLostStartDate!,
      );
    }

    context.read<ContactBloc>().add(
      FetchContactsEvent(
        search: '',
        isRefresh: true,
        statusProspectIds: widget.initialStatusIds,
        salesChannelIds: widget.initialSalesChannelIds,
        startDate: widget.initialStartDate,
        endDate: widget.initialEndDate,
        apptStartDate: widget.initialApptStartDate,
        apptEndDate: widget.initialApptEndDate,
        visitStartDate: widget.initialVisitStartDate,
        visitEndDate: widget.initialVisitEndDate,
        reserveStartDate: widget.initialReserveStartDate,
        reserveEndDate: widget.initialReserveEndDate,
        spStartDate: widget.initialSpStartDate,
        spEndDate: widget.initialSpEndDate,
        lostStartDate: widget.initialLostStartDate,
        lostEndDate: widget.initialLostEndDate,
        clearDates: widget.initialStartDate == null,
        clearApptDates: widget.initialApptStartDate == null,
        clearVisitDates: widget.initialVisitStartDate == null,
        clearReserveDates: widget.initialReserveStartDate == null,
        clearSpDates: widget.initialSpStartDate == null,
        clearLostDates: widget.initialLostStartDate == null,
      ),
    );

    context.read<ProspectStatusBloc>().add(FetchProspectStatusesEvent());
    context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));

    context.read<AuthBloc>().add(FetchPermissionsEvent(silent: true));
    context.read<ProfileBloc>().add(
      GetProfileEvent(forceRefresh: true, silent: true),
    );

    ApiConstants.settingsVersion.addListener(_onSettingsUpdated);
  }

  void _onSettingsUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ContactPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIds = widget.initialStatusIds;
    final oldIds = oldWidget.initialStatusIds;
    final statusChanged = newIds != null && newIds.isNotEmpty && newIds.toString() != (oldIds ?? []).toString();

    final newChannelIds = widget.initialSalesChannelIds;
    final oldChannelIds = oldWidget.initialSalesChannelIds;
    final salesChannelChanged = newChannelIds != null && newChannelIds.isNotEmpty && newChannelIds.toString() != (oldChannelIds ?? []).toString();

    if (statusChanged || salesChannelChanged) {
      _searchController.clear();
      final newLabel = widget.initialStartDate != null
          ? _resolveDateLabel(
              widget.initialStartDate!,
              widget.initialEndDate ?? widget.initialStartDate!,
            )
          : null;
      final newApptLabel = widget.initialApptStartDate != null
          ? _resolveDateLabel(
              widget.initialApptStartDate!,
              widget.initialApptEndDate ?? widget.initialApptStartDate!,
            )
          : null;
      final newVisitLabel = widget.initialVisitStartDate != null
          ? _resolveDateLabel(
              widget.initialVisitStartDate!,
              widget.initialVisitEndDate ?? widget.initialVisitStartDate!,
            )
          : null;
      final newReserveLabel = widget.initialReserveStartDate != null
          ? _resolveDateLabel(
              widget.initialReserveStartDate!,
              widget.initialReserveEndDate ?? widget.initialReserveStartDate!,
            )
          : null;
      final newSpLabel = widget.initialSpStartDate != null
          ? _resolveDateLabel(
              widget.initialSpStartDate!,
              widget.initialSpEndDate ?? widget.initialSpStartDate!,
            )
          : null;
      final newLostLabel = widget.initialLostStartDate != null
          ? _resolveDateLabel(
              widget.initialLostStartDate!,
              widget.initialLostEndDate ?? widget.initialLostStartDate!,
            )
          : null;
      setState(() {
        selectedDateLabel = newLabel;
        selectedApptDateLabel = newApptLabel;
        selectedVisitDateLabel = newVisitLabel;
        selectedReserveDateLabel = newReserveLabel;
        selectedSpDateLabel = newSpLabel;
        selectedLostDateLabel = newLostLabel;
      });
      context.read<ContactBloc>().add(
        FetchContactsEvent(
          search: '',
          isRefresh: true,
          statusProspectIds: newIds,
          salesChannelIds: newChannelIds,
          startDate: widget.initialStartDate,
          endDate: widget.initialEndDate,
          apptStartDate: widget.initialApptStartDate,
          apptEndDate: widget.initialApptEndDate,
          visitStartDate: widget.initialVisitStartDate,
          visitEndDate: widget.initialVisitEndDate,
          reserveStartDate: widget.initialReserveStartDate,
          reserveEndDate: widget.initialReserveEndDate,
          spStartDate: widget.initialSpStartDate,
          spEndDate: widget.initialSpEndDate,
          lostStartDate: widget.initialLostStartDate,
          lostEndDate: widget.initialLostEndDate,
          clearDates: widget.initialStartDate == null,
          clearApptDates: widget.initialApptStartDate == null,
          clearVisitDates: widget.initialVisitStartDate == null,
          clearReserveDates: widget.initialReserveStartDate == null,
          clearSpDates: widget.initialSpStartDate == null,
          clearLostDates: widget.initialLostStartDate == null,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.clear();

    _contactBloc.add(ClearContactsEvent());

    ApiConstants.settingsVersion.removeListener(_onSettingsUpdated);
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();

    contactEntity.clear();

    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<ContactBloc>().state;
      if (state.status != ContactStatus.loading && !state.hasReachedMax) {
        context.read<ContactBloc>().add(const FetchContactsEvent());
      }
    }
  }

  String _resolveDateLabel(String startDate, String endDate) {
    final now = AppTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fmt = DateFormat('yyyy-MM-dd');
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = startOfWeek.subtract(const Duration(days: 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);

    final lastYearStart = DateTime(now.year - 1, now.month, now.day);

    final presets = <List<String>>[
      ['Today', fmt.format(today), fmt.format(today)],
      ['Yesterday', fmt.format(yesterday), fmt.format(yesterday)],
      ['This Week', fmt.format(startOfWeek), fmt.format(today)],
      ['Last Week', fmt.format(startOfLastWeek), fmt.format(endOfLastWeek)],
      ['This Month', fmt.format(startOfMonth), fmt.format(today)],
      ['Last Month', fmt.format(startOfLastMonth), fmt.format(endOfLastMonth)],
      ['Last 1 Year', fmt.format(lastYearStart), fmt.format(today)],
    ];

    for (final p in presets) {
      if (p[1] == startDate && p[2] == endDate) return p[0];
    }
    return startDate == endDate ? startDate : '$startDate - $endDate';
  }

  String _normalizeSearch(String value) {
    final trimmed = value.trim();
    if (RegExp(r'^08\d+$').hasMatch(trimmed))
      return '628${trimmed.substring(2)}';
    if (trimmed.startsWith('+62')) return '62${trimmed.substring(3)}';
    return trimmed;
  }

  Future<void> _onRefresh() async {
    context.read<AuthBloc>().add(FetchPermissionsEvent());
    context.read<ContactBloc>().add(const FetchContactsEvent(isRefresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customHeader(context, 'Contacts'),
            SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customSearchField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 500),
                          () {
                            AnalyticsService.logEvent(
                              'contact_list_search_contacts',
                            );
                            contactEntity.clear();
                            context.read<ContactBloc>().add(
                              FetchContactsEvent(
                                search: _normalizeSearch(value),
                                isRefresh: true,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Expanded(
                      child: BlocConsumer<ContactBloc, ContactState>(
                        listenWhen: (prev, curr) => curr.status == ContactStatus.error && prev.status == ContactStatus.loading,
                        listener: (context, state) {
                          final msg = (state.errorMessage ?? '').replaceFirst('Exception: ', '').trim();
                          showErrorDialog(
                            context,
                            msg.isNotEmpty ? msg : 'Gagal memuat data kontak',
                          );
                        },
                        builder: (context, state) {
                          contactEntity = state.contacts;
                          if (state.status == ContactStatus.loading && contactEntity.isEmpty) {
                            return buildContactPageShimmer();
                          }
                          return Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildSortFilter(context),
                                      const SizedBox(width: 8),
                                      _buildFilterPill(context),
                                      const SizedBox(width: 10),
                                      ..._buildQuickDateChips(context),
                                    ],
                                  ),
                                ),
                              ),
                              _buildActiveChipsRow(context),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 4,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Total: ${NumberHelper.thousands(state.totalContacts ?? 0)} contacts',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(grey5Color),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    if (state.contacts.isEmpty) {
                                      return const Center(
                                        child: Text('Tidak ada data kontak'),
                                      );
                                    }
                                    return RefreshIndicator(
                                      onRefresh: _onRefresh,
                                      child: ListView.separated(
                                        controller: _scrollController,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemCount: state.hasReachedMax
                                            ? contactEntity.length
                                            : contactEntity.length + 1,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          if (index >= state.contacts.length) {
                                            return const ShimmerContactItem();
                                          }
                                          final contact = state.contacts[index];
                                          return RepaintBoundary(
                                            child: _buildListContacts(
                                              context,
                                              contact,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: PermissionsHelper.canCreateContact
          ? Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                onPressed: () {
                  AnalyticsService.logEvent('contact_list_add_contact');
                  context.pushNamed(
                    'formContact',
                    extra: ContactDetailArgs(page: 0),
                  );
                },
                backgroundColor: Color(primaryColor),
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Color(whiteColor)),
              ),
            )
          : null,
    );
  }

  List<Widget> _buildQuickDateChips(BuildContext context) {
    final configs = <({
      String preset,
      String label,
      String? currentLabel,
      String analyticsEvent,
      void Function(String start, String end, String label) onApply,
      VoidCallback onClear,
    })>[
      (
        preset: ApiConstants.prospectStatusApptRangePreset,
        label: 'Appt',
        currentLabel: selectedApptDateLabel,
        analyticsEvent: 'contact_list_quick_filter_appt_week',
        onApply: (start, end, label) {
          context.read<ContactBloc>().add(
            FetchContactsEvent(isRefresh: true, apptStartDate: start, apptEndDate: end),
          );
          setState(() => selectedApptDateLabel = label);
        },
        onClear: () {
          context.read<ContactBloc>().add(
            const FetchContactsEvent(isRefresh: true, clearApptDates: true),
          );
          setState(() => selectedApptDateLabel = null);
        },
      ),
      (
        preset: ApiConstants.prospectStatusVisitRangePreset,
        label: 'Visit',
        currentLabel: selectedVisitDateLabel,
        analyticsEvent: 'contact_list_quick_filter_visit_week',
        onApply: (start, end, label) {
          context.read<ContactBloc>().add(
            FetchContactsEvent(isRefresh: true, visitStartDate: start, visitEndDate: end),
          );
          setState(() => selectedVisitDateLabel = label);
        },
        onClear: () {
          context.read<ContactBloc>().add(
            const FetchContactsEvent(isRefresh: true, clearVisitDates: true),
          );
          setState(() => selectedVisitDateLabel = null);
        },
      ),
      (
        preset: ApiConstants.prospectStatusReserveRangePreset,
        label: 'Reserve',
        currentLabel: selectedReserveDateLabel,
        analyticsEvent: 'contact_list_quick_filter_reserve_week',
        onApply: (start, end, label) {
          context.read<ContactBloc>().add(
            FetchContactsEvent(isRefresh: true, reserveStartDate: start, reserveEndDate: end),
          );
          setState(() => selectedReserveDateLabel = label);
        },
        onClear: () {
          context.read<ContactBloc>().add(
            const FetchContactsEvent(isRefresh: true, clearReserveDates: true),
          );
          setState(() => selectedReserveDateLabel = null);
        },
      ),
      (
        preset: ApiConstants.prospectStatusSpRangePreset,
        label: 'SP',
        currentLabel: selectedSpDateLabel,
        analyticsEvent: 'contact_list_quick_filter_sp_week',
        onApply: (start, end, label) {
          context.read<ContactBloc>().add(
            FetchContactsEvent(isRefresh: true, spStartDate: start, spEndDate: end),
          );
          setState(() => selectedSpDateLabel = label);
        },
        onClear: () {
          context.read<ContactBloc>().add(
            const FetchContactsEvent(isRefresh: true, clearSpDates: true),
          );
          setState(() => selectedSpDateLabel = null);
        },
      ),
      (
        preset: ApiConstants.prospectStatusLostRangePreset,
        label: 'Lost',
        currentLabel: selectedLostDateLabel,
        analyticsEvent: 'contact_list_quick_filter_lost_week',
        onApply: (start, end, label) {
          context.read<ContactBloc>().add(
            FetchContactsEvent(isRefresh: true, lostStartDate: start, lostEndDate: end),
          );
          setState(() => selectedLostDateLabel = label);
        },
        onClear: () {
          context.read<ContactBloc>().add(
            const FetchContactsEvent(isRefresh: true, clearLostDates: true),
          );
          setState(() => selectedLostDateLabel = null);
        },
      ),
    ];

    final chips = <Widget>[];
    for (final config in configs) {
      // Setting kosong/tidak valid (mis. PROSPECT_STATUS_LOST_RANGE_PRESET = " ")
      // -> resolveRangePreset return null -> chip disembunyikan dari UI.
      final preset = DateHelper.resolveRangePreset(config.preset);
      if (preset == null) continue;
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(_quickDateChip(
        label: config.label,
        currentLabel: config.currentLabel,
        presetLabel: preset.label,
        onApply: () {
          AnalyticsService.logEvent(config.analyticsEvent);
          // Dihitung ulang saat tap (bukan pakai `preset` dari saat build) supaya
          // tanggalnya tetap real-time walau chip sudah lama tidak di-rebuild.
          final fresh = DateHelper.resolveRangePreset(config.preset)!;
          final fmt = DateFormat('yyyy-MM-dd');
          config.onApply(fmt.format(fresh.start), fmt.format(fresh.end), fresh.label);
        },
        onClear: config.onClear,
      ));
    }
    return chips;
  }

  Widget _quickDateChip({
    required String label,
    required String? currentLabel,
    required String presetLabel,
    required VoidCallback onApply,
    required VoidCallback onClear,
  }) {
    final isSelected = currentLabel == presetLabel;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isSelected ? onClear : onApply,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(primaryColor) : Color(whiteColor),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Color(primaryColor) : Color(transparentColor),
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Color(blackColor).withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$presetLabel $label',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Color(whiteColor) : Color(blackColor),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close_rounded, size: 14, color: Color(whiteColor)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(BuildContext context) {
    return BlocBuilder<ContactBloc, ContactState>(
      builder: (context, contactState) {
        final count = _activeFilterCount(contactState);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomFilterButton(
              label: 'Filter',
              isSelected: count > 0,
              onTap: _openingFilterSheet ? () {} : () => _openFilterSheet(context),
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
            if (count > 0)
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
                    '$count',
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
        );
      },
    );
  }

  Future<T> _waitUntilReady<T>(Stream<T> stream, bool Function(T) isReady, T current) {
    if (isReady(current)) return Future.value(current);
    return stream
        .firstWhere(isReady)
        .timeout(const Duration(seconds: 6), onTimeout: () => current);
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    AnalyticsService.logEvent('contact_list_open_filter_sheet');
    final statusBloc = context.read<ProspectStatusBloc>();
    final sourceBloc = context.read<InfoSourceBloc>();

    // Status/Sales Channel depend on their own blocs, loaded upfront — wait for
    // whichever hasn't finished loading yet so the sheet opens with those
    // accordions already populated instead of appearing empty/stuck. Sales
    // Channel Detail + hierarki sales (Owner/dst) sekarang paginated dan
    // di-fetch sendiri oleh masing-masing accordion saat dibuka, jadi tidak
    // perlu ditunggu di sini lagi.
    setState(() => _openingFilterSheet = true);
    await Future.wait([
      _waitUntilReady<ProspectStatusState>(
        statusBloc.stream,
        (s) => s.status != ProspectStatusEnum.initial && s.status != ProspectStatusEnum.loading,
        statusBloc.state,
      ),
      _waitUntilReady<InfoSourceState>(
        sourceBloc.stream,
        (s) => s.status != InfoSourceStatus.initial && s.status != InfoSourceStatus.loading,
        sourceBloc.state,
      ),
    ]);
    if (!context.mounted) return;
    setState(() => _openingFilterSheet = false);

    final contactState = context.read<ContactBloc>().state;
    final statusState = statusBloc.state;
    final sourceState = sourceBloc.state;

    final statusItems = statusState.status == ProspectStatusEnum.loaded
        ? statusState.statuses
              .map(
                (e) => OwnerDropdownItem(
                  id: e.statusProspectId,
                  name: e.statusProspectName,
                ),
              )
              .toList()
        : <OwnerDropdownItem>[];
    final channelItems = (sourceState.sourcesMap[1] ?? const <InfoSource>[])
        .map((e) => OwnerDropdownItem(id: e.id, name: e.name))
        .toList();

    final checkGroups = <ContactCheckGroup>[
      ContactCheckGroup(
        key: 'status',
        label: 'Status Prospek',
        section: 'Data Kontak',
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

    // Sales Channel Detail + hierarki sales (Owner/Executive/Supervisor/Manager/GM/
    // Team) — dedicated endpoint sendiri-sendiri (paginated + search di backend),
    // BUKAN diturunkan dari data /me profile seperti sebelumnya. Data di-fetch
    // bertahap oleh accordion-nya sendiri saat dibuka, lihat SalesHierarchyService.
    final hierarchyService = context.read<SalesHierarchyService>();
    final paginatedGroups = <PaginatedCheckGroup>[
      PaginatedCheckGroup(
        key: 'channelDetail',
        label: 'Sales Channel Detail',
        section: 'Data Kontak',
        fetchPage: hierarchyService.channelDetail,
      ),
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

    final initialChecks = <String, Set<int>>{
      'status': (contactState.statusProspectIds ?? const []).toSet(),
      'channel': (contactState.salesChannelIds ?? const []).toSet(),
      'channelDetail': (contactState.salesChannelDetailIds ?? const []).toSet(),
      'owner': (contactState.ownerIds ?? const []).toSet(),
      'executive': (contactState.salesExecutiveIds ?? const []).toSet(),
      'supervisor': (contactState.salesSupervisorIds ?? const []).toSet(),
      'manager': (contactState.salesManagerIds ?? const []).toSet(),
      'gm': (contactState.salesGeneralManagerIds ?? const []).toSet(),
      'team': (contactState.salesTeamIds ?? const []).toSet(),
    };

    DateRangeValue? dateValue(String? start, String? end, String? label) =>
        start == null
        ? null
        : DateRangeValue(
            label: label ?? start,
            start: start,
            end: end ?? start,
          );

    final initialDates = <String, DateRangeValue?>{
      'create': dateValue(
        contactState.startDate,
        contactState.endDate,
        selectedDateLabel,
      ),
      'appt': dateValue(
        contactState.apptStartDate,
        contactState.apptEndDate,
        selectedApptDateLabel,
      ),
      'visit': dateValue(
        contactState.visitStartDate,
        contactState.visitEndDate,
        selectedVisitDateLabel,
      ),
      'reserve': dateValue(
        contactState.reserveStartDate,
        contactState.reserveEndDate,
        selectedReserveDateLabel,
      ),
      'sp': dateValue(
        contactState.spStartDate,
        contactState.spEndDate,
        selectedSpDateLabel,
      ),
      'lost': dateValue(
        contactState.lostStartDate,
        contactState.lostEndDate,
        selectedLostDateLabel,
      ),
    };

    final result = await showModalBottomSheet<ContactFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContactFilterSheet(
        checkGroups: checkGroups,
        paginatedGroups: paginatedGroups,
        initialChecks: initialChecks,
        initialDates: initialDates,
        initialProject: contactState.lastProject,
      ),
    );

    if (result != null && context.mounted) {
      AnalyticsService.logEvent('contact_list_apply_filter_sheet');
      context.read<ContactBloc>().add(
        FetchContactsEvent(
          isRefresh: true,
          statusProspectIds: result.statusIds.toList(),
          clearStatus: result.statusIds.isEmpty,
          salesChannelIds: result.channelIds.toList(),
          clearSalesChannel: result.channelIds.isEmpty,
          salesChannelDetailIds: result.channelDetailIds.toList(),
          clearSalesChannelDetail: result.channelDetailIds.isEmpty,
          ownerIds: result.ownerIds.toList(),
          clearOwner: result.ownerIds.isEmpty,
          salesExecutiveIds: result.executiveIds.toList(),
          clearSalesExecutive: result.executiveIds.isEmpty,
          salesSupervisorIds: result.supervisorIds.toList(),
          clearSalesSupervisor: result.supervisorIds.isEmpty,
          salesManagerIds: result.managerIds.toList(),
          clearSalesManager: result.managerIds.isEmpty,
          salesGeneralManagerIds: result.generalManagerIds.toList(),
          clearSalesGeneralManager: result.generalManagerIds.isEmpty,
          salesTeamIds: result.teamIds.toList(),
          clearSalesTeam: result.teamIds.isEmpty,
          startDate: result.createDate?.start,
          endDate: result.createDate?.end,
          clearDates: result.createDate == null,
          apptStartDate: result.apptDate?.start,
          apptEndDate: result.apptDate?.end,
          clearApptDates: result.apptDate == null,
          visitStartDate: result.visitDate?.start,
          visitEndDate: result.visitDate?.end,
          clearVisitDates: result.visitDate == null,
          reserveStartDate: result.reserveDate?.start,
          reserveEndDate: result.reserveDate?.end,
          clearReserveDates: result.reserveDate == null,
          spStartDate: result.spDate?.start,
          spEndDate: result.spDate?.end,
          clearSpDates: result.spDate == null,
          lostStartDate: result.lostDate?.start,
          lostEndDate: result.lostDate?.end,
          clearLostDates: result.lostDate == null,
          lastProject: result.project,
          clearProject: result.project == null,
        ),
      );
      setState(() {
        selectedDateLabel = result.createDate?.label;
        selectedApptDateLabel = result.apptDate?.label;
        selectedVisitDateLabel = result.visitDate?.label;
        selectedReserveDateLabel = result.reserveDate?.label;
        selectedSpDateLabel = result.spDate?.label;
        selectedLostDateLabel = result.lostDate?.label;
      });
    }
  }

  Widget _buildActiveChipsRow(BuildContext context) {
    return BlocBuilder<ContactBloc, ContactState>(
      builder: (context, contactState) {
        return BlocBuilder<ProspectStatusBloc, ProspectStatusState>(
          builder: (context, statusState) {
            return BlocBuilder<InfoSourceBloc, InfoSourceState>(
              builder: (context, sourceState) {
                return BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, profileState) {
                    final chips = _buildActiveChips(
                      contactState,
                      statusState,
                      sourceState,
                      profileState,
                    );
                    if (chips.isEmpty) return const SizedBox.shrink();
                    return SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: chips.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, i) {
                          if (i == chips.length) {
                            return Center(
                              child: TextButton(
                                onPressed: () => _clearAllFilters(context),
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
                              chip.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(primaryColor),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: Color(
                              primaryColor,
                            ).withValues(alpha: 0.1),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: chip.onRemove,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: BorderSide.none,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  List<_ActiveChip> _buildActiveChips(
    ContactState s,
    ProspectStatusState statusState,
    InfoSourceState sourceState,
    ProfileState profileState,
  ) {
    final chips = <_ActiveChip>[];

    final statusIds = s.statusProspectIds ?? const <int>[];
    if (statusIds.isNotEmpty) {
      String label = 'Status';
      if (statusState.status == ProspectStatusEnum.loaded) {
        if (statusIds.length == 1) {
          final st = statusState.statuses
              .cast<ProspectStatusEntity?>()
              .firstWhere(
                (e) => e?.statusProspectId == statusIds.first,
                orElse: () => null,
              );
          if (st != null) label = st.statusProspectName;
        } else {
          label = '${statusIds.length} Statuses';
        }
      }
      chips.add(
        _ActiveChip(
          label,
          () => context.read<ContactBloc>().add(
            const FetchContactsEvent(isRefresh: true, clearStatus: true),
          ),
        ),
      );
    }

    final channelIds = s.salesChannelIds ?? const <int>[];
    if (channelIds.isNotEmpty) {
      String label = 'Sales Channel';
      final sources = sourceState.sourcesMap[1];
      if (sources != null) {
        if (channelIds.length == 1) {
          final found = sources.cast<InfoSource?>().firstWhere(
            (e) => e?.id == channelIds.first,
            orElse: () => null,
          );
          if (found != null) label = found.name;
        } else {
          label = '${channelIds.length} Sales Channels';
        }
      }
      chips.add(
        _ActiveChip(
          label,
          () => context.read<ContactBloc>().add(
            const FetchContactsEvent(isRefresh: true, clearSalesChannel: true),
          ),
        ),
      );
    }

    final channelDetailIds = s.salesChannelDetailIds ?? const <int>[];
    if (channelDetailIds.isNotEmpty) {
      String label = 'Sales Channel Detail';
      final detailSources = sourceState.sourcesMap[2];
      if (detailSources != null) {
        if (channelDetailIds.length == 1) {
          final found = detailSources.cast<InfoSource?>().firstWhere(
            (e) => e?.id == channelDetailIds.first,
            orElse: () => null,
          );
          if (found != null) label = found.name;
        } else {
          label = '${channelDetailIds.length} Sales Channel Details';
        }
      }
      chips.add(
        _ActiveChip(
          label,
          () => context.read<ContactBloc>().add(
            const FetchContactsEvent(isRefresh: true, clearSalesChannelDetail: true),
          ),
        ),
      );
    }

    if (profileState is ProfileLoaded) {
      void addRoleChip(
        List<int>? ids,
        String role,
        String singularLabel,
        String pluralLabel,
        FetchContactsEvent Function() clearEvent,
      ) {
        final selected = ids ?? const <int>[];
        if (selected.isEmpty) return;
        final candidates = _collectOwnerCandidates(profileState.profile)
            .where(
              (c) => role == 'owner'
                  ? true
                  : _classifyPosition(c.positionName) == role,
            )
            .toList();
        String label = singularLabel;
        if (selected.length == 1) {
          final match = candidates.cast<_OwnerCandidate?>().firstWhere(
            (c) => role == 'owner'
                ? c?.id == selected.first
                : c?.salesPersonId == selected.first,
            orElse: () => null,
          );
          if (match != null) label = match.name;
        } else {
          label = '${selected.length} $pluralLabel';
        }
        chips.add(
          _ActiveChip(
            label,
            () => context.read<ContactBloc>().add(clearEvent()),
          ),
        );
      }

      addRoleChip(
        s.ownerIds,
        'owner',
        'Owner',
        'Owners',
        () => const FetchContactsEvent(isRefresh: true, clearOwner: true),
      );
      addRoleChip(
        s.salesExecutiveIds,
        'se',
        'Sales Executive',
        'Sales Executives',
        () => const FetchContactsEvent(
          isRefresh: true,
          clearSalesExecutive: true,
        ),
      );
      addRoleChip(
        s.salesSupervisorIds,
        'spv',
        'Sales Supervisor',
        'Sales Supervisors',
        () => const FetchContactsEvent(
          isRefresh: true,
          clearSalesSupervisor: true,
        ),
      );
      addRoleChip(
        s.salesManagerIds,
        'sm',
        'Sales Manager',
        'Sales Managers',
        () =>
            const FetchContactsEvent(isRefresh: true, clearSalesManager: true),
      );
      addRoleChip(
        s.salesGeneralManagerIds,
        'gm',
        'General Manager',
        'General Managers',
        () => const FetchContactsEvent(
          isRefresh: true,
          clearSalesGeneralManager: true,
        ),
      );

      final teamIds = s.salesTeamIds ?? const <int>[];
      if (teamIds.isNotEmpty) {
        final candidates = _collectSalesTeamCandidates(profileState.profile);
        final label = teamIds.length == 1
            ? (candidates
                      .cast<_TeamCandidate?>()
                      .firstWhere(
                        (c) => c?.id == teamIds.first,
                        orElse: () => null,
                      )
                      ?.name ??
                  'Sales Team')
            : '${teamIds.length} Sales Teams';
        chips.add(
          _ActiveChip(
            label,
            () => context.read<ContactBloc>().add(
              const FetchContactsEvent(isRefresh: true, clearSalesTeam: true),
            ),
          ),
        );
      }
    }

    void addDateChip(
      String label,
      String? start,
      String? selLabel,
      VoidCallback onClear,
    ) {
      if (start == null) return;
      chips.add(_ActiveChip('$label: ${selLabel ?? start}', onClear));
    }

    addDateChip('Create Date', s.startDate, selectedDateLabel, () {
      context.read<ContactBloc>().add(
        const FetchContactsEvent(isRefresh: true, clearDates: true),
      );
      setState(() => selectedDateLabel = null);
    });
    addDateChip('Appt Date', s.apptStartDate, selectedApptDateLabel, () {
      context.read<ContactBloc>().add(
        const FetchContactsEvent(isRefresh: true, clearApptDates: true),
      );
      setState(() => selectedApptDateLabel = null);
    });
    addDateChip('Visit Date', s.visitStartDate, selectedVisitDateLabel, () {
      context.read<ContactBloc>().add(
        const FetchContactsEvent(isRefresh: true, clearVisitDates: true),
      );
      setState(() => selectedVisitDateLabel = null);
    });
    addDateChip(
      'Reserve Date',
      s.reserveStartDate,
      selectedReserveDateLabel,
      () {
        context.read<ContactBloc>().add(
          const FetchContactsEvent(isRefresh: true, clearReserveDates: true),
        );
        setState(() => selectedReserveDateLabel = null);
      },
    );
    addDateChip('SP Date', s.spStartDate, selectedSpDateLabel, () {
      context.read<ContactBloc>().add(
        const FetchContactsEvent(isRefresh: true, clearSpDates: true),
      );
      setState(() => selectedSpDateLabel = null);
    });
    addDateChip('Lost Date', s.lostStartDate, selectedLostDateLabel, () {
      context.read<ContactBloc>().add(
        const FetchContactsEvent(isRefresh: true, clearLostDates: true),
      );
      setState(() => selectedLostDateLabel = null);
    });

    if (s.lastProject != null) {
      chips.add(
        _ActiveChip(
          'Project: ${s.lastProject}',
          () => context.read<ContactBloc>().add(
            const FetchContactsEvent(isRefresh: true, clearProject: true),
          ),
        ),
      );
    }

    return chips;
  }

  void _clearAllFilters(BuildContext context) {
    AnalyticsService.logEvent('contact_list_clear_all_filters');
    context.read<ContactBloc>().add(
      const FetchContactsEvent(
        isRefresh: true,
        clearStatus: true,
        clearSalesChannel: true,
        clearSalesChannelDetail: true,
        clearOwner: true,
        clearSalesExecutive: true,
        clearSalesSupervisor: true,
        clearSalesManager: true,
        clearSalesGeneralManager: true,
        clearSalesTeam: true,
        clearDates: true,
        clearApptDates: true,
        clearVisitDates: true,
        clearReserveDates: true,
        clearSpDates: true,
        clearLostDates: true,
        clearProject: true,
      ),
    );
    setState(() {
      selectedDateLabel = null;
      selectedApptDateLabel = null;
      selectedVisitDateLabel = null;
      selectedReserveDateLabel = null;
      selectedSpDateLabel = null;
      selectedLostDateLabel = null;
    });
  }
}

class _ActiveChip {
  final String label;
  final VoidCallback onRemove;
  _ActiveChip(this.label, this.onRemove);
}

int _activeFilterCount(ContactState s) {
  var n = 0;
  if ((s.statusProspectIds ?? const []).isNotEmpty) n++;
  if ((s.salesChannelIds ?? const []).isNotEmpty) n++;
  if ((s.salesChannelDetailIds ?? const []).isNotEmpty) n++;
  if ((s.ownerIds ?? const []).isNotEmpty) n++;
  if ((s.salesExecutiveIds ?? const []).isNotEmpty) n++;
  if ((s.salesSupervisorIds ?? const []).isNotEmpty) n++;
  if ((s.salesManagerIds ?? const []).isNotEmpty) n++;
  if ((s.salesGeneralManagerIds ?? const []).isNotEmpty) n++;
  if ((s.salesTeamIds ?? const []).isNotEmpty) n++;
  if (s.startDate != null) n++;
  if (s.apptStartDate != null) n++;
  if (s.visitStartDate != null) n++;
  if (s.reserveStartDate != null) n++;
  if (s.spStartDate != null) n++;
  if (s.lostStartDate != null) n++;
  if (s.lastProject != null) n++;
  return n;
}

String _normalizePhone(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (cleaned.startsWith('+62')) return '62${cleaned.substring(3)}';
  if (cleaned.startsWith('08')) return '628${cleaned.substring(2)}';
  return cleaned;
}

class _OwnerCandidate {
  final int? id;
  final int? salesPersonId;
  final String name;
  final String? subtitle;
  final String? positionName;
  const _OwnerCandidate({
    this.id,
    this.salesPersonId,
    required this.name,
    this.subtitle,
    this.positionName,
  });
}

class _TeamCandidate {
  final int id;
  final String name;
  const _TeamCandidate({required this.id, required this.name});
}

List<_TeamCandidate> _collectSalesTeamCandidates(UserProfileEntity user) {
  final Map<int, String> teams = {};

  void addTeam(int? id, String? name) {
    if (id != null && name != null && name.isNotEmpty) {
      teams[id] = name;
    }
  }

  addTeam(user.salesTeamId, user.salesTeamName);

  void walkSubordinates(List<HierarchyNodeEntity> nodes) {
    for (final n in nodes) {
      addTeam(n.salesTeamId, n.salesTeamName);
      if (n.subordinates.isNotEmpty) walkSubordinates(n.subordinates);
    }
  }

  walkSubordinates(user.subordinates);

  for (final t in user.salesTeamHierarchy) {
    addTeam(t.salesTeamId, t.salesTeamName);
  }

  return teams.entries
      .map((e) => _TeamCandidate(id: e.key, name: e.value))
      .toList();
}

List<_OwnerCandidate> _collectOwnerCandidates(UserProfileEntity user) {
  final List<_OwnerCandidate> items = [
    _OwnerCandidate(
      id: user.userId,
      salesPersonId: user.salesPersonId,
      name: user.fullName,
      subtitle: user.positionName,
      positionName: user.positionName,
    ),
  ];

  if (user.subordinates.isNotEmpty) {
    void addSubs(List<HierarchyNodeEntity> subs) {
      for (final s in subs) {
        items.add(
          _OwnerCandidate(
            id: s.userId,
            salesPersonId: s.salesPersonId,
            name: s.fullName,
            subtitle: s.positionName,
            positionName: s.positionName,
          ),
        );
        if (s.subordinates.isNotEmpty) addSubs(s.subordinates);
      }
    }

    addSubs(user.subordinates);
  } else {
    final seen = <int>{user.userId};
    void addGroupUsers(List<GroupHierarchyEntity> groups) {
      for (final g in groups) {
        for (final u in g.users) {
          if (seen.contains(u.userId)) continue;
          seen.add(u.userId);
          items.add(
            _OwnerCandidate(
              id: u.userId,
              name: u.fullName,
              subtitle: g.groupName,
              positionName: null,
            ),
          );
        }
        if (g.children.isNotEmpty) addGroupUsers(g.children);
      }
    }

    addGroupUsers(user.groupHierarchy);

    void addTeamMembers(List<SalesTeamMemberEntity> members, String teamName) {
      for (final m in members) {
        if (m.userId != null && !seen.contains(m.userId!)) {
          seen.add(m.userId!);
          items.add(
            _OwnerCandidate(
              id: m.userId,
              salesPersonId: m.salesPersonId,
              name: m.fullName,
              subtitle: '$teamName - ${m.positionName ?? ''}',
              positionName: m.positionName,
            ),
          );
        }
        if (m.subordinates.isNotEmpty) addTeamMembers(m.subordinates, teamName);
      }
    }

    for (final team in user.salesTeamHierarchy) {
      addTeamMembers(team.members, team.salesTeamName);
    }
  }

  return items;
}

// Position names are free-text from the backend (e.g. "Sales Executive - Jakarta 1"),
// so roles are detected via keyword match. "general manager" must be checked before
// "manager" since it also contains that word.
String? _classifyPosition(String? positionName) {
  if (positionName == null) return null;
  final p = positionName.toLowerCase();
  if (p.contains('general manager')) return 'gm';
  if (p.contains('supervisor')) return 'spv';
  if (p.contains('manager')) return 'sm';
  if (p.contains('executive')) return 'se';
  return null;
}

const List<MapEntry<String, String>> _sortOptions = [
  MapEntry('created_desc', 'Dibuat: Terbaru'),
  MapEntry('created_asc', 'Dibuat: Terlama'),
  MapEntry('name_asc', 'Nama: A-Z'),
  MapEntry('name_desc', 'Nama: Z-A'),
  MapEntry('appt_desc', 'Appt: Terbaru'),
  MapEntry('appt_asc', 'Appt: Terlama'),
  MapEntry('visit_desc', 'Visit: Terbaru'),
  MapEntry('visit_asc', 'Visit: Terlama'),
  MapEntry('reserve_desc', 'Reserve: Terbaru'),
  MapEntry('reserve_asc', 'Reserve: Terlama'),
  MapEntry('sp_desc', 'SP: Terbaru'),
  MapEntry('sp_asc', 'SP: Terlama'),
  MapEntry('lost_desc', 'Lost: Terbaru'),
  MapEntry('lost_asc', 'Lost: Terlama'),
];

Widget _buildSortFilter(BuildContext context) {
  return BlocBuilder<ContactBloc, ContactState>(
    builder: (context, contactState) {
      final currentSort = contactState.sort ?? 'created_desc';
      final isSelected = currentSort != 'created_desc';
      final selectedIndex = _sortOptions.indexWhere(
        (e) => e.key == currentSort,
      );
      final label = selectedIndex >= 0
          ? _sortOptions[selectedIndex].value
          : 'Urutkan';

      return CustomFilterButton(
        label: label,
        isSelected: isSelected,
        onClear: isSelected
            ? () {
                AnalyticsService.logEvent('contact_list_clear_sort_filter');
                context.read<ContactBloc>().add(
                  const FetchContactsEvent(isRefresh: true, clearSort: true),
                );
              }
            : null,
        onTap: () async {
          AnalyticsService.logEvent('contact_list_filter_sort');
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
              allowClear: isSelected,
              preserveOrder: true,
            ),
          );

          if (result is List) {
            if (context.mounted) {
              AnalyticsService.logEvent('contact_list_clear_sort_filter');
              context.read<ContactBloc>().add(
                const FetchContactsEvent(isRefresh: true, clearSort: true),
              );
            }
            return;
          }

          if (result != null && context.mounted) {
            final selected = result as OwnerDropdownItem;
            final key = _sortOptions[selected.id!].key;
            context.read<ContactBloc>().add(
              FetchContactsEvent(
                isRefresh: true,
                sort: key == 'created_desc' ? null : key,
                clearSort: key == 'created_desc',
              ),
            );
          }
        },
      );
    },
  );
}

Widget _buildListContacts(BuildContext context, ContactEntity contact) {
  return GestureDetector(
    onTap: () {
      AnalyticsService.logEvent('contact_list_open_contact_detail');
      context.pushNamed(
        'detailContact',
        extra: ContactDetailArgs(dataContact: contact, page: 2),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Color(shadowColor).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(primaryColor).withValues(alpha: 0.1),
                  child: Text(
                    getInitials(contact.fullName ?? 'No Name'),
                    style: TextStyle(
                      color: Color(primaryColor),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        contact.fullName ?? 'No Name',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(blue2Color),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contact.whatsappNumber != null
                            ? _normalizePhone(contact.whatsappNumber!)
                            : 'No Phone',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(grey5Color),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contact.ownerName ?? 'No Owner',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(grey5Color),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildContactBadges(context, contact),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              AnalyticsService.logEvent('contact_list_open_contact_options');
              showCustomBottomSheet(
                context: context,
                child: _buildContactOptions(context, contact),
              );
            },
            child: Icon(Icons.more_vert, size: 27, color: Color(blackColor)),
          ),
        ],
      ),
    ),
  );
}

Widget _buildContactBadges(BuildContext context, ContactEntity contact) {
  return BlocBuilder<ProspectStatusBloc, ProspectStatusState>(
    builder: (context, statusState) {
      return BlocBuilder<InfoSourceBloc, InfoSourceState>(
        builder: (context, sourceState) {
          ProspectStatusEntity? status;
          if (statusState.status == ProspectStatusEnum.loaded) {
            status = statusState.statuses
                .cast<ProspectStatusEntity?>()
                .firstWhere(
                  (e) => e?.statusProspectId == contact.statusProspectId,
                  orElse: () => null,
                );
          }

          final sources = sourceState.sourcesMap[1];
          InfoSource? channel;
          if (sources != null) {
            channel = sources.cast<InfoSource?>().firstWhere(
              (e) => e?.id == contact.salesChannelId,
              orElse: () => null,
            );
          }

          final statusLabel = status == null
              ? null
              : (status.statusValue.isNotEmpty
                    ? status.statusValue
                    : status.statusProspectName);
          final group = status?.group ?? 'db';

          final channelLabel = channel?.name.split('-').first.trim();

          final hasStatus = statusLabel != null && statusLabel.isNotEmpty;
          final hasChannel = channelLabel != null && channelLabel.isNotEmpty;

          if (!hasStatus && !hasChannel) return const SizedBox.shrink();

          return SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasStatus) _statusChip(statusLabel, group: group),
                if (hasStatus && hasChannel) const SizedBox(height: 6),
                if (hasChannel) _channelChip(channelLabel),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _statusChip(String label, {required String group}) {
  final color = statusGroupColor(group);
  return Container(
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      // color: color.withValues(alpha: 0.15),
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

Widget _buildContactOptions(BuildContext context, ContactEntity contact) {
  return Container(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconLink(
          context,
          icEdit,
          "Edit Contact",
          () {
            AnalyticsService.logEvent('contact_list_edit_contact');
            context.pushNamed(
              'formContact',
              extra: ContactDetailArgs(dataContact: contact, page: 1),
            );
          },
          hidden:
              !(PermissionsHelper.canEditContact && (contact.canEdit ?? true)),
        ),
        _buildIconLink(
          context,
          icDelete,
          "Delete Contact",
          () {
            AnalyticsService.logEvent('contact_list_delete_contact');
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Confirm'),
                content: Text('Delete this contact?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      AnalyticsService.logEvent(
                        'contact_list_cancel_delete_contact',
                      );
                      Navigator.pop(ctx);
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      AnalyticsService.logEvent(
                        'contact_list_confirm_delete_contact',
                      );
                      Navigator.pop(ctx);
                      context.read<ContactBloc>().add(
                        DeleteContactEvent(contact.contactId!),
                      );
                    },
                    child: Text('Delete'),
                  ),
                ],
              ),
            );
          },
          hidden:
              !(PermissionsHelper.canDeleteContact &&
                  (contact.canDelete ?? true)),
        ),
        _buildIconLink(context, icShare, "Share Contact", () {
          ShareHelper.shareContact(contact);
        }),
      ],
    ),
  );
}

Widget _buildIconLink(
  BuildContext context,
  String asset,
  String label,
  VoidCallback onTap, {
  Color? color,
  bool disabled = false,
  bool hidden = false,
}) {
  if (hidden) return const SizedBox.shrink();
  return InkWell(
    onTap: disabled
        ? null
        : () {
            Navigator.pop(context);
            onTap();
          },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          BgIcon(
            asset: asset,
            onTap: null,
            color: disabled ? Color(greyShade500) : color,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: disabled ? Color(greyShade500) : Color(blue2Color),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}
