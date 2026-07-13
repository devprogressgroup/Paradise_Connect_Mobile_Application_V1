import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/utils/share_helper.dart';
import 'package:progress_group/core/utils/widget/custom_bg_icon.dart';
import 'package:progress_group/core/constants/colors.dart';

import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/date_filter.dart';
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
import '../../../domain/entities/info_source/info_source.dart';
import '../../../../../core/utils/widget/custom_filter_button.dart';
import '../../../../../core/utils/widget/error_dialog.dart';
import '../../../domain/entities/prospect/prospect_status.dart';

class ContactPage extends StatefulWidget {
  final List<int>? initialStatusIds;
  final List<int>? initialSalesChannelIds;
  final String? initialStartDate;
  final String? initialEndDate;
  const ContactPage({super.key, this.initialStatusIds, this.initialSalesChannelIds, this.initialStartDate, this.initialEndDate});

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

    context.read<ContactBloc>().add(FetchContactsEvent(
      search: '',
      isRefresh: true,
      statusProspectIds: widget.initialStatusIds,
      salesChannelIds: widget.initialSalesChannelIds,
      startDate: widget.initialStartDate,
      endDate: widget.initialEndDate,
    ));

    context.read<ProspectStatusBloc>().add(FetchProspectStatusesEvent());
    context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));


    context.read<AuthBloc>().add(FetchPermissionsEvent(silent: true));
    context.read<ProfileBloc>().add(GetProfileEvent(forceRefresh: true, silent: true));
  }

  @override
  void didUpdateWidget(ContactPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIds = widget.initialStatusIds;
    final oldIds = oldWidget.initialStatusIds;
    final statusChanged = newIds != null &&
        newIds.isNotEmpty &&
        newIds.toString() != (oldIds ?? []).toString();

    final newChannelIds = widget.initialSalesChannelIds;
    final oldChannelIds = oldWidget.initialSalesChannelIds;
    final salesChannelChanged = newChannelIds != null &&
        newChannelIds.isNotEmpty &&
        newChannelIds.toString() != (oldChannelIds ?? []).toString();

    if (statusChanged || salesChannelChanged) {
      _searchController.clear();
      final newLabel = widget.initialStartDate != null
          ? _resolveDateLabel(
              widget.initialStartDate!,
              widget.initialEndDate ?? widget.initialStartDate!,
            )
          : null;
      setState(() => selectedDateLabel = newLabel);
      context.read<ContactBloc>().add(FetchContactsEvent(
        search: '',
        isRefresh: true,
        statusProspectIds: newIds,
        salesChannelIds: newChannelIds,
        startDate: widget.initialStartDate,
        endDate: widget.initialEndDate,
      ));
    }
  }

  @override
  void dispose() {
    _searchController.clear();

    _contactBloc.add(const FetchContactsEvent(search: '', isRefresh: true));
    _contactBloc.add(ClearContactsEvent());

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
    if (RegExp(r'^08\d+$').hasMatch(trimmed)) return '628${trimmed.substring(2)}';
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
                  children: [
                    customSearchField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          AnalyticsService.logEvent('contact_list_search_contacts');
                          contactEntity.clear();
                          context.read<ContactBloc>().add(
                            FetchContactsEvent(search: _normalizeSearch(value), isRefresh: true),
                          );
                        });
                      },
                    ),
                    Expanded(
                      child: BlocConsumer<ContactBloc, ContactState>(
                       
                       
                       
                        listenWhen: (prev, curr) =>
                            curr.status == ContactStatus.error && prev.status == ContactStatus.loading,
                        listener: (context, state) {
                         
                          final msg = (state.errorMessage ?? '').replaceFirst('Exception: ', '').trim();
                          showErrorDialog(context, msg.isNotEmpty ? msg : 'Gagal memuat data kontak');
                        },
                        builder: (context, state) {
                          contactEntity = state.contacts;
                          if (state.status == ContactStatus.loading && contactEntity.isEmpty) {
                            return buildContactPageShimmer();
                          }
                          return Column(
                            children: [
                              SizedBox(
                                height: 50,
                                child: BlocBuilder<ProfileBloc, ProfileState>(
                                  builder: (context, profileState) {
                                    final availableRoles = profileState is ProfileLoaded
                                        ? _collectOwnerCandidates(profileState.profile)
                                            .map((c) => _classifyPosition(c.positionName))
                                            .whereType<String>()
                                            .toSet()
                                        : const <String>{};

                                    final teamCandidates = profileState is ProfileLoaded
                                        ? _collectSalesTeamCandidates(profileState.profile)
                                        : const <_TeamCandidate>[];

                                    final slots = <int>[0, 1, 2, 3, 4, 5, 6, 7];
                                    if (availableRoles.contains('se')) slots.add(8);
                                    if (availableRoles.contains('spv')) slots.add(9);
                                    if (availableRoles.contains('sm')) slots.add(10);
                                    if (availableRoles.contains('gm')) slots.add(11);
                                    if (teamCandidates.isNotEmpty) slots.add(12);

                                    return ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: slots.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                                  itemBuilder: (context, i) {
                                    final index = slots[i];
                                    if (index == 0) {
                                      return BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          return BlocBuilder<ProfileBloc, ProfileState>(
                                            builder: (context, profileState) {
                                              String label = 'Owner';
                                              final ownerIds = contactState.ownerIds ?? const <int>[];
                                              bool isSelected = ownerIds.isNotEmpty;

                                              if (isSelected && profileState is ProfileLoaded) {
                                                if (ownerIds.length == 1) {
                                                  label = _resolveNameById(profileState.profile, ownerIds.first) ?? label;
                                                } else {
                                                  label = "${ownerIds.length} Owners";
                                                }
                                              }

                                              return CustomFilterButton(
                                                label: label,
                                                isSelected: isSelected,
                                                onTap: () async {
                                                  AnalyticsService.logEvent('contact_list_filter_owner');
                                                  if (profileState is ProfileLoaded) {
                                                    final ownerItems = _collectOwnerCandidates(profileState.profile)
                                                        .map((c) => OwnerDropdownItem(id: c.id, name: c.name, subtitle: c.subtitle))
                                                        .toList();

                                                    final result = await context.pushNamed('detailContactDropdown',extra: ContactDropdownArgs(title: 'Pilih Owner',items: ownerItems,selectedIds: contactState.ownerIds,isMultiSelect: true,),);

                                                    if (result != null) {
                                                      final selected = result as List<OwnerDropdownItem>;
                                                      context.read<ContactBloc>().add(
                                                        FetchContactsEvent(
                                                          ownerIds: selected.map((e) => e.id).whereType<int>().toList(),
                                                          isRefresh: true,
                                                          clearOwner: selected.isEmpty,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              );
                                            },
                                          );
                                        },
                                      );
                                    }
                                    if (index == 1) {
                                      return BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          return BlocBuilder<ProspectStatusBloc, ProspectStatusState>(
                                            builder: (context, statusState) {
                                              String label = 'Status';
                                              bool isSelected = contactState.statusProspectIds != null && contactState.statusProspectIds!.isNotEmpty;

                                              if (isSelected && statusState.status == ProspectStatusEnum.loaded) {
                                                if (contactState.statusProspectIds!.length == 1) {
                                                  final status = statusState.statuses.cast<ProspectStatusEntity?>().firstWhere((e) => e?.statusProspectId == contactState.statusProspectIds!.first, orElse: () => null,);
                                                  if (status != null) label = status.statusProspectName;
                                                } else {
                                                  label = "${contactState.statusProspectIds!.length} Statuses";
                                                }
                                              }

                                              return CustomFilterButton(
                                                label: label,
                                                isSelected: isSelected,
                                                onTap: () async {
                                                  AnalyticsService.logEvent('contact_list_filter_status');
                                                  if (statusState.status == ProspectStatusEnum.loaded) {
                                                    final List<OwnerDropdownItem> statusItems = statusState.statuses.map((e) => OwnerDropdownItem(id: e.statusProspectId, name: e.statusProspectName,)).toList();

                                                    final result = await context.pushNamed('detailContactDropdown', extra: ContactDropdownArgs(title: 'Pilih Status Prospect', items: statusItems, selectedIds: contactState.statusProspectIds, isMultiSelect: true,),);

                                                    if (result != null) {
                                                      final selected = result as List<OwnerDropdownItem>;
                                                      if (context.mounted) {
                                                        context.read<ContactBloc>().add(
                                                          FetchContactsEvent(
                                                            statusProspectIds: selected.map((e) => e.id).whereType<int>().toList(),
                                                            isRefresh: true,
                                                            clearStatus: selected.isEmpty,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  }
                                                },
                                              );
                                            },
                                          );
                                        },
                                      );
                                    }

                                    if (index == 2) {
                                      return BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          bool isSelected = contactState.startDate != null && contactState.endDate != null;

                                          String label = contactState.startDate != null ? (selectedDateLabel ?? 'Create Date') : 'Create Date';

                                          return CustomFilterButton(
                                            label: label,
                                            isSelected: isSelected,
                                            onTap: () async {
                                              AnalyticsService.logEvent('contact_list_filter_date', parameters: {'filter': 'create_date'});
                                              final result = await context.pushNamed<DateFilterResult>(
                                                'dateFilter',
                                                extra: {
                                                  'label': selectedDateLabel,
                                                  'startDate': contactState.startDate,
                                                  'endDate': contactState.endDate,
                                                  'isSingleSelect': true,
                                                },
                                              );

                                              if (result != null) {
                                                if (result.isClear) {
                                                  context.read<ContactBloc>().add(const FetchContactsEvent(startDate: null,endDate: null,isRefresh: true,clearDates: true,),);

                                                  setState(() => selectedDateLabel = null);
                                                } else {
                                                  context.read<ContactBloc>().add(
                                                    FetchContactsEvent(
                                                      startDate: result.startDate,
                                                      endDate: result.endDate,
                                                      isRefresh: true,
                                                    ),
                                                  );

                                                  setState(() => selectedDateLabel = result.label);
                                                }
                                              }
                                            },
                                          );
                                        },
                                      );
                                    }
                                    if (index == 3) {
                                      return BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          final isSelected = contactState.apptStartDate != null && contactState.apptEndDate != null;
                                          final label = isSelected ? (selectedApptDateLabel ?? 'Appt Date') : 'Appt Date';
                                          return CustomFilterButton(
                                            label: label,
                                            isSelected: isSelected,
                                            onTap: () async {
                                              AnalyticsService.logEvent('contact_list_filter_date', parameters: {'filter': 'appt_date'});
                                              final result = await context.pushNamed<DateFilterResult>(
                                                'dateFilter',
                                                extra: {
                                                  'label': selectedApptDateLabel,
                                                  'startDate': contactState.apptStartDate,
                                                  'endDate': contactState.apptEndDate,
                                                  'isSingleSelect': true,
                                                },
                                              );
                                              if (result != null) {
                                                if (result.isClear) {
                                                  context.read<ContactBloc>().add(const FetchContactsEvent(isRefresh: true, clearApptDates: true));
                                                  setState(() => selectedApptDateLabel = null);
                                                } else {
                                                  context.read<ContactBloc>().add(FetchContactsEvent(apptStartDate: result.startDate, apptEndDate: result.endDate, isRefresh: true));
                                                  setState(() => selectedApptDateLabel = result.label);
                                                }
                                              }
                                            },
                                          );
                                        },
                                      );
                                    }

                                    if (index == 4) {
                                      return BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          final isSelected = contactState.visitStartDate != null && contactState.visitEndDate != null;
                                          final label = isSelected ? (selectedVisitDateLabel ?? 'Visit Date') : 'Visit Date';
                                          return CustomFilterButton(
                                            label: label,
                                            isSelected: isSelected,
                                            onTap: () async {
                                              AnalyticsService.logEvent('contact_list_filter_date', parameters: {'filter': 'visit_date'});
                                              final result = await context.pushNamed<DateFilterResult>(
                                                'dateFilter',
                                                extra: {
                                                  'label': selectedVisitDateLabel,
                                                  'startDate': contactState.visitStartDate,
                                                  'endDate': contactState.visitEndDate,
                                                  'isSingleSelect': true,
                                                },
                                              );
                                              if (result != null) {
                                                if (result.isClear) {
                                                  context.read<ContactBloc>().add(const FetchContactsEvent(isRefresh: true, clearVisitDates: true));
                                                  setState(() => selectedVisitDateLabel = null);
                                                } else {
                                                  context.read<ContactBloc>().add(FetchContactsEvent(visitStartDate: result.startDate, visitEndDate: result.endDate, isRefresh: true));
                                                  setState(() => selectedVisitDateLabel = result.label);
                                                }
                                              }
                                            },
                                          );
                                        },
                                      );
                                    }

                                    if (index == 5) {
                                      return BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          final isSelected = contactState.reserveStartDate != null && contactState.reserveEndDate != null;
                                          final label = isSelected ? (selectedReserveDateLabel ?? 'Reserve Date') : 'Reserve Date';
                                          return CustomFilterButton(
                                            label: label,
                                            isSelected: isSelected,
                                            onTap: () async {
                                              AnalyticsService.logEvent('contact_list_filter_date', parameters: {'filter': 'reserve_date'});
                                              final result = await context.pushNamed<DateFilterResult>(
                                                'dateFilter',
                                                extra: {
                                                  'label': selectedReserveDateLabel,
                                                  'startDate': contactState.reserveStartDate,
                                                  'endDate': contactState.reserveEndDate,
                                                  'isSingleSelect': true,
                                                },
                                              );
                                              if (result != null) {
                                                if (result.isClear) {
                                                  context.read<ContactBloc>().add(const FetchContactsEvent(isRefresh: true, clearReserveDates: true));
                                                  setState(() => selectedReserveDateLabel = null);
                                                } else {
                                                  context.read<ContactBloc>().add(FetchContactsEvent(reserveStartDate: result.startDate, reserveEndDate: result.endDate, isRefresh: true));
                                                  setState(() => selectedReserveDateLabel = result.label);
                                                }
                                              }
                                            },
                                          );
                                        },
                                      );
                                    }

                                    if (index == 6) {
                                      return BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          final isSelected = contactState.spStartDate != null && contactState.spEndDate != null;
                                          final label = isSelected ? (selectedSpDateLabel ?? 'SP Date') : 'SP Date';
                                          return CustomFilterButton(
                                            label: label,
                                            isSelected: isSelected,
                                            onTap: () async {
                                              AnalyticsService.logEvent('contact_list_filter_date', parameters: {'filter': 'sp_date'});
                                              final result = await context.pushNamed<DateFilterResult>(
                                                'dateFilter',
                                                extra: {
                                                  'label': selectedSpDateLabel,
                                                  'startDate': contactState.spStartDate,
                                                  'endDate': contactState.spEndDate,
                                                  'isSingleSelect': true,
                                                },
                                              );
                                              if (result != null) {
                                                if (result.isClear) {
                                                  context.read<ContactBloc>().add(const FetchContactsEvent(isRefresh: true, clearSpDates: true));
                                                  setState(() => selectedSpDateLabel = null);
                                                } else {
                                                  context.read<ContactBloc>().add(FetchContactsEvent(spStartDate: result.startDate, spEndDate: result.endDate, isRefresh: true));
                                                  setState(() => selectedSpDateLabel = result.label);
                                                }
                                              }
                                            },
                                          );
                                        },
                                      );
                                    }

                                    if (index == 7) {
                                      return BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          return BlocBuilder<InfoSourceBloc, InfoSourceState>(
                                            builder: (context, sourceState) {
                                              String label = 'Sales Channel';
                                              bool isSelected = contactState.salesChannelIds != null && contactState.salesChannelIds!.isNotEmpty;

                                              if (isSelected) {
                                                final sources = sourceState.sourcesMap[1];
                                                if (contactState.salesChannelIds!.length == 1 && sources != null) {
                                                  final found = sources.cast<InfoSource?>().firstWhere(
                                                        (e) => e?.id == contactState.salesChannelIds!.first,
                                                        orElse: () => null,
                                                      );
                                                  if (found != null) label = found.name;
                                                } else {
                                                  label = "${contactState.salesChannelIds!.length} Sales Channels";
                                                }
                                              }

                                              return CustomFilterButton(
                                                label: label,
                                                isSelected: isSelected,
                                                onTap: () async {
                                                  final sources = sourceState.sourcesMap[1];
                                                  if (sources != null) {
                                                    final sourceItems = sources.map((e) => OwnerDropdownItem(id: e.id, name: e.name)).toList();
                                                    final result = await context.pushNamed(
                                                      'detailContactDropdown',
                                                      extra: ContactDropdownArgs(
                                                        title: 'Pilih Sales Channel',
                                                        items: sourceItems,
                                                        selectedIds: contactState.salesChannelIds,
                                                        isMultiSelect: true,
                                                      ),
                                                    );
                                                    if (result != null) {
                                                      final selected = result as List<OwnerDropdownItem>;
                                                      if (context.mounted) {
                                                        context.read<ContactBloc>().add(
                                                          FetchContactsEvent(
                                                            salesChannelIds: selected.map((e) => e.id).whereType<int>().toList(),
                                                            isRefresh: true,
                                                            clearSalesChannel: selected.isEmpty,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  } else {
                                                    context.read<InfoSourceBloc>().add(const FetchInfoSourcesEvent(type: 1));
                                                  }
                                                },
                                              );
                                            },
                                          );
                                        },
                                      );
                                    }

                                    if (index == 8) {
                                      return _buildRolePositionFilter(
                                        context,
                                        role: 'se',
                                        label: 'Sales Executive',
                                        pluralLabel: 'Sales Executives',
                                        analyticsEvent: 'contact_list_filter_sales_executive',
                                      );
                                    }
                                    if (index == 9) {
                                      return _buildRolePositionFilter(
                                        context,
                                        role: 'spv',
                                        label: 'Sales Supervisor',
                                        pluralLabel: 'Sales Supervisors',
                                        analyticsEvent: 'contact_list_filter_sales_supervisor',
                                      );
                                    }
                                    if (index == 10) {
                                      return _buildRolePositionFilter(
                                        context,
                                        role: 'sm',
                                        label: 'Sales Manager',
                                        pluralLabel: 'Sales Managers',
                                        analyticsEvent: 'contact_list_filter_sales_manager',
                                      );
                                    }
                                    if (index == 11) {
                                      return _buildRolePositionFilter(
                                        context,
                                        role: 'gm',
                                        label: 'General Manager',
                                        pluralLabel: 'General Managers',
                                        analyticsEvent: 'contact_list_filter_general_manager',
                                      );
                                    }

                                    if (index == 12) {
                                      return _buildSalesTeamFilter(context);
                                    }

                                    return null;
                                  },
                                    );
                                  },
                                ),
                              ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Total: ${NumberHelper.thousands(state.totalContacts??0)} contacts',
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
                                      return const Center(child: Text('Tidak ada data kontak'));
                                    }
                                    return RefreshIndicator(
                                      onRefresh: _onRefresh,
                                      child: ListView.separated(
                                        controller: _scrollController,
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        itemCount: state.hasReachedMax ? contactEntity.length : contactEntity.length + 1,
                                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          if (index >= state.contacts.length) {
                                            return const ShimmerContactItem();
                                          }
                                          final contact = state.contacts[index];
                                          return RepaintBoundary(child: _buildListContacts(context, contact));
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
                  context.pushNamed('formContact', extra: ContactDetailArgs(page: 0));
                },
                backgroundColor: Color(primaryColor),
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Color(whiteColor)),
              ),
            )
          : null,
    );
  }
}

String _normalizePhone(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (cleaned.startsWith('+62')) return '62${cleaned.substring(3)}';
  if (cleaned.startsWith('08')) return '628${cleaned.substring(2)}';
  return cleaned;
}

class _OwnerCandidate {
  final int? id;
  final String name;
  final String? subtitle;
  final String? positionName;
  const _OwnerCandidate({this.id, required this.name, this.subtitle, this.positionName});
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

  return teams.entries.map((e) => _TeamCandidate(id: e.key, name: e.value)).toList();
}

List<_OwnerCandidate> _collectOwnerCandidates(UserProfileEntity user) {
  final List<_OwnerCandidate> items = [
    _OwnerCandidate(id: user.userId, name: user.fullName, subtitle: user.positionName, positionName: user.positionName),
  ];

  if (user.subordinates.isNotEmpty) {
    void addSubs(List<HierarchyNodeEntity> subs) {
      for (final s in subs) {
        items.add(_OwnerCandidate(id: s.userId, name: s.fullName, subtitle: s.positionName, positionName: s.positionName));
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
          items.add(_OwnerCandidate(id: u.userId, name: u.fullName, subtitle: g.groupName, positionName: null));
        }
        if (g.children.isNotEmpty) addGroupUsers(g.children);
      }
    }
    addGroupUsers(user.groupHierarchy);

    void addTeamMembers(List<SalesTeamMemberEntity> members, String teamName) {
      for (final m in members) {
        if (m.userId != null && !seen.contains(m.userId!)) {
          seen.add(m.userId!);
          items.add(_OwnerCandidate(
            id: m.userId,
            name: m.fullName,
            subtitle: '$teamName - ${m.positionName ?? ''}',
            positionName: m.positionName,
          ));
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

String? _resolveNameById(UserProfileEntity user, int id) {
  if (user.userId == id) return user.fullName;

  HierarchyNodeEntity? found;
  void search(List<HierarchyNodeEntity> nodes) {
    for (final n in nodes) {
      if (n.userId == id) found = n;
      if (found == null && n.subordinates.isNotEmpty) search(n.subordinates);
    }
  }
  search(user.subordinates);
  if (found != null) return found!.fullName;

  String? foundLabel;
  void searchGroup(List<GroupHierarchyEntity> groups) {
    for (final g in groups) {
      for (final u in g.users) {
        if (u.userId == id) {
          foundLabel = u.fullName;
          return;
        }
      }
      if (foundLabel == null && g.children.isNotEmpty) searchGroup(g.children);
    }
  }
  searchGroup(user.groupHierarchy);
  if (foundLabel != null) return foundLabel;

  void searchTeam(List<SalesTeamMemberEntity> members) {
    for (final m in members) {
      if (m.userId == id) {
        foundLabel = m.fullName;
        return;
      }
      if (foundLabel == null && m.subordinates.isNotEmpty) searchTeam(m.subordinates);
    }
  }
  for (final team in user.salesTeamHierarchy) {
    if (foundLabel != null) break;
    searchTeam(team.members);
  }
  return foundLabel;
}

Widget _buildRolePositionFilter(
  BuildContext context, {
  required String role,
  required String label,
  required String pluralLabel,
  required String analyticsEvent,
}) {
  return BlocBuilder<ContactBloc, ContactState>(
    builder: (context, contactState) {
      return BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, profileState) {
          String displayLabel = label;
          bool isSelected = false;
          List<_OwnerCandidate> candidates = const [];

          if (profileState is ProfileLoaded) {
            candidates = _collectOwnerCandidates(profileState.profile)
                .where((c) => _classifyPosition(c.positionName) == role)
                .toList();
            final candidateIds = candidates.map((c) => c.id).whereType<int>().toSet();
            final roleSelectedIds = (contactState.ownerIds ?? []).where(candidateIds.contains).toList();

            if (roleSelectedIds.isNotEmpty) {
              isSelected = true;
              displayLabel = roleSelectedIds.length == 1
                  ? (_resolveNameById(profileState.profile, roleSelectedIds.first) ?? label)
                  : '${roleSelectedIds.length} $pluralLabel';
            }
          }

          return CustomFilterButton(
            label: displayLabel,
            isSelected: isSelected,
            onTap: () async {
              AnalyticsService.logEvent(analyticsEvent);
              if (profileState is! ProfileLoaded) return;

              final candidateIds = candidates.map((c) => c.id).whereType<int>().toSet();
              final currentRoleSelected = (contactState.ownerIds ?? []).where(candidateIds.contains).toList();
              final items = candidates.map((c) => OwnerDropdownItem(id: c.id, name: c.name, subtitle: c.subtitle)).toList();

              final result = await context.pushNamed(
                'detailContactDropdown',
                extra: ContactDropdownArgs(
                  title: 'Pilih $label',
                  items: items,
                  selectedIds: currentRoleSelected,
                  isMultiSelect: true,
                ),
              );

              if (result != null && context.mounted) {
                final selected = result as List<OwnerDropdownItem>;
                final selectedIds = selected.map((e) => e.id).whereType<int>().toSet();
                final others = (contactState.ownerIds ?? []).where((id) => !candidateIds.contains(id));
                final merged = {...others, ...selectedIds}.toList();

                context.read<ContactBloc>().add(
                  FetchContactsEvent(
                    ownerIds: merged,
                    isRefresh: true,
                    clearOwner: merged.isEmpty,
                  ),
                );
              }
            },
          );
        },
      );
    },
  );
}

Widget _buildSalesTeamFilter(BuildContext context) {
  return BlocBuilder<ContactBloc, ContactState>(
    builder: (context, contactState) {
      return BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, profileState) {
          String label = 'Sales Team';
          bool isSelected = false;
          List<_TeamCandidate> candidates = const [];

          if (profileState is ProfileLoaded) {
            candidates = _collectSalesTeamCandidates(profileState.profile);
            final salesTeamIds = contactState.salesTeamIds ?? const <int>[];

            if (salesTeamIds.isNotEmpty) {
              isSelected = true;
              label = salesTeamIds.length == 1
                  ? (candidates.cast<_TeamCandidate?>().firstWhere((e) => e?.id == salesTeamIds.first, orElse: () => null)?.name ?? label)
                  : '${salesTeamIds.length} Sales Teams';
            }
          }

          return CustomFilterButton(
            label: label,
            isSelected: isSelected,
            onTap: () async {
              AnalyticsService.logEvent('contact_list_filter_sales_team');
              if (candidates.isEmpty) return;

              final items = candidates.map((c) => OwnerDropdownItem(id: c.id, name: c.name)).toList();

              final result = await context.pushNamed(
                'detailContactDropdown',
                extra: ContactDropdownArgs(
                  title: 'Pilih Sales Team',
                  items: items,
                  selectedIds: contactState.salesTeamIds,
                  isMultiSelect: true,
                ),
              );

              if (result != null && context.mounted) {
                final selected = result as List<OwnerDropdownItem>;
                context.read<ContactBloc>().add(
                  FetchContactsEvent(
                    salesTeamIds: selected.map((e) => e.id).whereType<int>().toList(),
                    isRefresh: true,
                    clearSalesTeam: selected.isEmpty,
                  ),
                );
              }
            },
          );
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
                  child: Text(getInitials(contact.fullName ?? 'No Name'),style: TextStyle(color: Color(primaryColor), fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(contact.fullName ?? 'No Name',style: TextStyle(fontSize: 16, color: Color(blue2Color), fontWeight: FontWeight.bold),overflow: TextOverflow.ellipsis),
                      Text(contact.whatsappNumber != null ? _normalizePhone(contact.whatsappNumber!) : 'No Phone',style: TextStyle(fontSize: 14, color: Color(grey5Color)),overflow: TextOverflow.ellipsis),
                      Text(contact.ownerName ??'No Owner',style: TextStyle(fontSize: 12, color: Color(grey5Color)),overflow: TextOverflow.ellipsis),
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
              showCustomBottomSheet(context: context,child: _buildContactOptions(context, contact),);
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
            status = statusState.statuses.cast<ProspectStatusEntity?>().firstWhere(
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
              : (status.statusValue.isNotEmpty ? status.statusValue : status.statusProspectName);
          final group = status?.group ?? 'db';

          final channelLabel = channel?.name.split('-').first.trim();

          final hasStatus = statusLabel != null && statusLabel.isNotEmpty;
          final hasChannel = channelLabel != null && channelLabel.isNotEmpty;

          if (!hasStatus && !hasChannel) return const SizedBox.shrink();

          return SizedBox(
            width:50,
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

Color _statusGroupColor(String group) {
  switch (group) {
    case 'lost':
      return Color(redColor);
    case 'appt':
      return Color(primaryColor);
    case 'visitor':
      return Color(warningColor);
    case 'reserve':
      return Color(lightGreenColor);
    case 'sp':
      return Color(darkGreenColor);
    case 'db':
    default:
      return Color(purpleColor);
  }
}

Widget _statusChip(String label, {required String group}) {
  final color = _statusGroupColor(group);
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
      border: Border.all(color:color.withValues(alpha: 0.15)),
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
        _buildIconLink(context, icEdit, "Edit Contact", () {
            AnalyticsService.logEvent('contact_list_edit_contact');
            context.pushNamed('formContact', extra: ContactDetailArgs(dataContact: contact, page: 1));
          }, hidden: !(PermissionsHelper.canEditContact && (contact.canEdit ?? true))),
        _buildIconLink(context, icDelete, "Delete Contact", () {
            AnalyticsService.logEvent('contact_list_delete_contact');
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Confirm'),
                content: Text('Delete this contact?'),
                actions: [
                  TextButton(onPressed: () {
                    AnalyticsService.logEvent('contact_list_cancel_delete_contact');
                    Navigator.pop(ctx);
                  }, child: Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      AnalyticsService.logEvent('contact_list_confirm_delete_contact');
                      Navigator.pop(ctx);
                      context.read<ContactBloc>().add(DeleteContactEvent(contact.contactId!));
                    },
                    child: Text('Delete'),
                  ),
                ],
              ),
            );
          }, hidden: !(PermissionsHelper.canDeleteContact && (contact.canDelete ?? true))),
        _buildIconLink(context, icShare, "Share Contact", () {
          ShareHelper.shareContact(contact);
        }),
      ],
    ),
  );
}

Widget _buildIconLink(BuildContext context, String asset, String label, VoidCallback onTap, {Color? color, bool disabled = false, bool hidden = false}) {
  if (hidden) return const SizedBox.shrink();
  return InkWell(
    onTap: disabled ? null : () {
      Navigator.pop(context);
      onTap();
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          BgIcon(asset: asset, onTap: null, color: disabled ? Color(greyShade500) : color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 16, color: disabled ? Color(greyShade500) : Color(blue2Color), fontWeight: FontWeight.w400)),
        ],
      ),
    ),
  );
}
