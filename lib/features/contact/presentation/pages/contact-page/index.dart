import 'dart:async';
import 'package:flutter/material.dart';
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
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/date_filter.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/auth/domain/entities/user_profile.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import '../../../../../core/utils/widget/custom_buttomsheet.dart';
import '../../state/contact/contact_bloc.dart';
import '../../state/contact/contact_event.dart';
import '../../state/contact/contact_state.dart';
import '../../state/prospect_status/prospect_status_bloc.dart';
import '../../state/prospect_status/prospect_status_event.dart';
import '../../state/prospect_status/prospect_status_state.dart';
import '../../../../../core/utils/widget/custom_filter_button.dart';
import '../../../../../core/utils/widget/error_dialog.dart';
import '../../../domain/entities/prospect/prospect_status.dart';

class ContactPage extends StatefulWidget {
  final List<int>? initialStatusIds;
  const ContactPage({super.key, this.initialStatusIds});

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

  @override
  void initState() {
    super.initState();

    _searchController.clear();

    _scrollController = ScrollController()..addListener(_onScroll);

    context.read<ContactBloc>().add(FetchContactsEvent(
      search: '',
      isRefresh: true,
      statusProspectIds: widget.initialStatusIds,
    ));

    context.read<ProspectStatusBloc>().add(FetchProspectStatusesEvent());
  }

  @override
  void didUpdateWidget(ContactPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIds = widget.initialStatusIds;
    final oldIds = oldWidget.initialStatusIds;
    final changed = newIds != null &&
        newIds.isNotEmpty &&
        newIds.toString() != (oldIds ?? []).toString();
    if (changed) {
      _searchController.clear();
      context.read<ContactBloc>().add(FetchContactsEvent(
        search: '',
        isRefresh: true,
        statusProspectIds: newIds,
      ));
    }
  }

  @override
  void dispose() {
    _searchController.clear();

    context.read<ContactBloc>().add(
      const FetchContactsEvent(search: '', isRefresh: true),
    );

    context.read<ContactBloc>().add(ClearContactsEvent());

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

  String _normalizeSearch(String value) {
    final trimmed = value.trim();
    if (RegExp(r'^08\d+$').hasMatch(trimmed)) return '628${trimmed.substring(2)}';
    if (trimmed.startsWith('+62')) return '62${trimmed.substring(3)}';
    return trimmed;
  }

  Future<void> _onRefresh() async {
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
                          contactEntity.clear();
                          context.read<ContactBloc>().add(
                            FetchContactsEvent(search: _normalizeSearch(value), isRefresh: true),
                          );
                        });
                      },
                    ),
                    Expanded(
                      child: BlocConsumer<ContactBloc, ContactState>(
                        listenWhen: (prev, curr) => curr.status == ContactStatus.error && prev.status != ContactStatus.error,
                        listener: (context, state) {
                          showErrorDialog(context, state.errorMessage ?? 'Gagal memuat data kontak');
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
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 7,
                                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          return BlocBuilder<ProfileBloc, ProfileState>(
                                            builder: (context, profileState) {
                                              String label = 'Owner';
                                              bool isSelected = contactState.ownerIds != null && contactState.ownerIds!.isNotEmpty;

                                              if (isSelected && profileState is ProfileLoaded) {
                                                if (contactState.ownerIds!.length == 1) {
                                                  final id = contactState.ownerIds!.first;
                                                  if (profileState.profile.userId == id) {
                                                    label = profileState.profile.fullName;
                                                  } else {
                                                    HierarchyNodeEntity? found;
                                                    void search(List<HierarchyNodeEntity> nodes) {
                                                      for (var n in nodes) {
                                                        if (n.userId == id) found = n;
                                                        if (found == null && n.subordinates.isNotEmpty)
                                                          search(n.subordinates);
                                                      }
                                                    }

                                                    search(profileState.profile.subordinates);
                                                    if (found != null) label = found!.fullName;
                                                  }
                                                } else {
                                                  label = "${contactState.ownerIds!.length} Owners";
                                                }
                                              }

                                              return CustomFilterButton(
                                                label: label,
                                                isSelected: isSelected,
                                                onTap: () async {
                                                  if (profileState is ProfileLoaded) {
                                                    final user = profileState.profile;
                                                    final List<OwnerDropdownItem> ownerItems = [];

                                                    ownerItems.add(OwnerDropdownItem(
                                                      id: user.userId,
                                                      name: user.fullName,
                                                      subtitle: user.positionName,
                                                    ));

                                                    void addSubs(List<HierarchyNodeEntity> subs) {
                                                      for (var s in subs) {
                                                        ownerItems.add(OwnerDropdownItem(
                                                          id: s.userId,
                                                          name: s.fullName,
                                                          subtitle: s.positionName,
                                                        ));
                                                        if (s.subordinates.isNotEmpty)
                                                          addSubs(s.subordinates);
                                                      }
                                                    }

                                                    addSubs(user.subordinates);

                                                    final result = await context.pushNamed('detailContactDropdown',extra: ContactDropdownArgs(title: 'Pilih Owner',items: ownerItems,selectedIds: contactState.ownerIds,isMultiSelect: true,),);

                                                    if (result != null) {
                                                      final selected = result as List<OwnerDropdownItem>;
                                                      context.read<ContactBloc>().add(
                                                        FetchContactsEvent(
                                                          ownerIds: selected.map((e) => e.id!).toList(),
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
                                                  if (statusState.status == ProspectStatusEnum.loaded) {
                                                    final List<OwnerDropdownItem> statusItems = statusState.statuses.map((e) => OwnerDropdownItem(id: e.statusProspectId, name: e.statusProspectName,)).toList();

                                                    final result = await context.pushNamed('detailContactDropdown', extra: ContactDropdownArgs(title: 'Pilih Status Prospect', items: statusItems, selectedIds: contactState.statusProspectIds, isMultiSelect: true,),);

                                                    if (result != null) {
                                                      final selected = result as List<OwnerDropdownItem>;
                                                      if (context.mounted) {
                                                        context.read<ContactBloc>().add(
                                                          FetchContactsEvent(
                                                            statusProspectIds: selected.map((e) => e.id!).toList(),
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

                                    return null;
                                  },
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          onPressed: () {
            context.pushNamed('formContact', extra: ContactDetailArgs(page: 0));
          },
          backgroundColor: Color(primaryColor),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

String _normalizePhone(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (cleaned.startsWith('+62')) return '62${cleaned.substring(3)}';
  if (cleaned.startsWith('08')) return '628${cleaned.substring(2)}';
  return cleaned;
}

Widget _buildListContacts(BuildContext context, ContactEntity contact) {
  return GestureDetector(
    onTap: () {
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
                      Text(contact.ownerName ??'-',style: TextStyle(fontSize: 12, color: Color(grey5Color)),overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              showCustomBottomSheet(context: context,child: _buildContactOptions(context, contact),);
            },
            child: Icon(Icons.more_vert, size: 27, color: Color(blackColor)),
          ),
        ],
      ),
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
          context.pushNamed('formContact',extra: ContactDetailArgs(dataContact: contact, page: 1),);
        }),
        _buildIconLink(context, icDelete, "Delete Contact", () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Confirm'),
              content: Text('Delete this contact?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx),child: Text('Cancel'),),
                TextButton(onPressed: () {
                    Navigator.pop(ctx);
                    context.read<ContactBloc>().add(DeleteContactEvent(contact.contactId!));
                  },
                  child: Text('Delete'),
                ),
              ],
            ),
          );
        }),
        _buildIconLink(context, icShare, "Share Contact", () {
          ShareHelper.shareContact(contact);
        }),
      ],
    ),
  );
}

Widget _buildIconLink(BuildContext context, String asset, String label, VoidCallback onTap, {Color? color,}) {
  return InkWell(
    onTap: () {
      Navigator.pop(context);
      onTap();
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          BgIcon(asset: asset, onTap: null, color: color),
          const SizedBox(width: 10),
          Text(label,style: TextStyle(fontSize: 16, color: Color(blue2Color), fontWeight: FontWeight.w400)),
        ],
      ),
    ),
  );
}
