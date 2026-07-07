import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/features/auth/domain/entities/user_profile.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/data/models/dropdown/date_filter.dart';
import 'package:progress_group/features/contact/domain/entities/prospect/prospect_status.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_event.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_state.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_event.dart';
import 'package:progress_group/features/contact/presentation/state/prospect_status/prospect_status_state.dart';
import 'package:progress_group/features/inbox/data/arguments/inbox_detail_args.dart';
import 'package:progress_group/features/inbox/domain/entities/inbox_contact_entity.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_block.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_event.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_statte.dart';
import 'package:progress_group/features/inbox/presentation/state/whatsapp_device/whatsapp_device_bloc.dart';
import 'package:progress_group/features/inbox/presentation/state/whatsapp_qr/whatsapp_qr_bloc.dart';


import '../../../../../core/constants/assets.dart';
import '../../../../../core/utils/widget/custom_button.dart';
import '../../../../../core/utils/widget/error_dialog.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  bool isFilterPhone = false;

  final TextEditingController searchTC = TextEditingController();
  final FocusNode searchFN = FocusNode();
  Timer? _debounce;

  late ScrollController _personalScrollController;
  late ScrollController _groupScrollController;
  int _cPage = 1;
  int _gPage = 1;
  bool _isFetchingMore = false;
  String? selectedDateLabel;

  @override
  void dispose() {
    _debounce?.cancel();
    searchTC.dispose();
    searchFN.dispose();
    _personalScrollController.dispose();
    _groupScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _personalScrollController = ScrollController()..addListener(_onScroll);
    _groupScrollController = ScrollController()..addListener(_onScroll);
    _fetchInbox();
    final statusState = context.read<ProspectStatusBloc>().state;
    if (statusState.status == ProspectStatusEnum.initial) {
      context.read<ProspectStatusBloc>().add(const FetchProspectStatusesEvent());
    }
  }

  void _onScroll() {
    final pc = _personalScrollController;
    final gc = _groupScrollController;
    
    bool isPersonalAtBottom = pc.hasClients && pc.position.pixels >= pc.position.maxScrollExtent - 200;
    bool isGroupAtBottom = gc.hasClients && gc.position.pixels >= gc.position.maxScrollExtent - 200;

    if ((isPersonalAtBottom || isGroupAtBottom) && !_isFetchingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    _isFetchingMore = true;
    _cPage++;
    _gPage++;
    _fetchInbox(isLoadMore: true);
  }

  Future<void> _fetchInbox({String? search, bool isLoadMore = false}) async {
    if (!isLoadMore) {
      _cPage = 1;
      _gPage = 1;
      context.read<AuthBloc>().add(FetchPermissionsEvent());
    }

    final contactState = context.read<ContactBloc>().state;

    context.read<InboxContactBloc>().add(GetInboxContactsEvent(
      search: search ?? searchTC.text,
      cPage: _cPage,
      gPage: _gPage,
      salesExecutiveIds: contactState.ownerIds,
      statusProspectId: (contactState.statusProspectIds != null && contactState.statusProspectIds!.isNotEmpty) ? contactState.statusProspectIds!.first : null,
      startDate: contactState.startDate,
      endDate: contactState.endDate,
      isLoadMore: isLoadMore,
    ));
    _isFetchingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContactBloc, ContactState>(
      listener: (context, state) {
        if (state.status == ContactStatus.loading) {
          _fetchInbox();
        }
      },
      child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customHeader(context, 'Whatsapp'),
          SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding:  EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: customSearchField(
                          controller: searchTC,
                          focusNode: searchFN,
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) _debounce?.cancel();
                            _debounce = Timer(const Duration(milliseconds: 500), () {
                              _fetchInbox(search: value);
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isFilterPhone = !isFilterPhone;
                            if (isFilterPhone) {
                              context.read<WhatsappDeviceBloc>().add(GetWhatsappDevicesEvent());
                            }
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Color(whiteColor),
                            border: Border.all(color: Color(greenPercentColor), width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(icContactDetailWA,width: 5,height: 5, color: Color(greenPercentColor),)
                        ),
                      ),
                    ],
                  ),
                  if(isFilterPhone)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(whiteColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: BlocConsumer<WhatsappDeviceBloc, WhatsappDeviceState>(
                        listenWhen: (prev, curr) => curr is WhatsappDeviceError && prev is! WhatsappDeviceError,
                        listener: (context, state) {
                          if (state is WhatsappDeviceError) {
                           
                            showErrorDialog(context, 'Gagal memuat perangkat WhatsApp');
                          }
                        },
                        builder: (context, state) {
                          if (state is WhatsappDeviceLoading) {
                            return const ShimmerInboxItem();
                          }
                          if (state is WhatsappDeviceLoaded) {
                            if (state.devices.isEmpty) {
                              return const Center(child: Text("Tidak ada device"));
                            }
                            return SizedBox(
                              height: 120,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: state.devices.map((device) {
                                    return Column(
                                      children: [
                                        _buildListPhone(
                                          phone: device.whatsappNumber,
                                          name: device.fullName ?? "-",
                                          image: device.status == "CONNECTED" ? icContactDetailWA : icQR,
                                          colorImg: device.status == "CONNECTED"
                                              ? Color(greenPercentColor)
                                              : Color(primaryColor),
                                          onTap: () {
                                            if (device.status != "CONNECTED") {
                                              context.read<WhatsappQrBloc>().add(
                                                    StartQrSessionEvent(device.sessionCode),
                                                  );
                                              _showInboxQRDialog(device.sessionCode);
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 5),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  BlocBuilder<InboxContactBloc, InboxContactState>(
                    builder: (context, inboxState) {
                      if (inboxState is InboxContactLoading) {
                        return buildInboxFilterShimmer();
                      }
                      return Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          BlocBuilder<ProfileBloc, ProfileState>(
                            builder: (context, profileState) {
                              return BlocBuilder<ContactBloc, ContactState>(
                                builder: (context, contactState) {
                                  String label = 'Owner';
                                  bool isSelected = contactState.ownerIds != null && contactState.ownerIds!.isNotEmpty;
                    
                                  if (isSelected && profileState is ProfileLoaded) {
                                    final user = profileState.profile;
                    
                                    String? findName(int? id) {
                                      if (id == null) return null;
                                      if (user.userId == id) return user.fullName;
                                      HierarchyNodeEntity? found;
                                      void search(List<HierarchyNodeEntity> nodes) {
                                        for (var n in nodes) {
                                          if (n.userId == id) found = n;
                                          if (found == null && n.subordinates.isNotEmpty) search(n.subordinates);
                                        }
                                      }
                                      search(user.subordinates);
                                      if (found != null) return found!.fullName;
                                      String? groupFound;
                                      void searchGroup(List<GroupHierarchyEntity> groups) {
                                        for (final g in groups) {
                                          for (final u in g.users) {
                                            if (u.userId == id) { groupFound = u.fullName; return; }
                                          }
                                          if (groupFound == null && g.children.isNotEmpty) searchGroup(g.children);
                                        }
                                      }
                                      searchGroup(user.groupHierarchy);
                                      if (groupFound != null) return groupFound;
                                      void searchTeam(List<SalesTeamMemberEntity> members) {
                                        for (final m in members) {
                                          if (m.userId == id) { groupFound = m.fullName; return; }
                                          if (groupFound == null && m.subordinates.isNotEmpty) searchTeam(m.subordinates);
                                        }
                                      }
                                      for (final team in user.salesTeamHierarchy) {
                                        if (groupFound != null) break;
                                        searchTeam(team.members);
                                      }
                                      return groupFound;
                                    }
                    
                                    if (contactState.ownerIds!.length == 1) {
                                      label = findName(contactState.ownerIds!.first) ?? "Filtered";
                                    } else {
                                      label = "${contactState.ownerIds!.length} Owners";
                                    }
                                  }
                    
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: CustomFilterButton(
                                      label: label,
                                      isSelected: isSelected,
                                      onTap: () async {
                                        if (profileState is ProfileLoaded) {
                                          final user = profileState.profile;
                                          final List<OwnerDropdownItem> ownerItems = [];
                    
                                          ownerItems.add(OwnerDropdownItem(id: user.userId, name: user.fullName, subtitle: user.positionName));

                                          if (user.subordinates.isNotEmpty) {
                                            void addSubs(List<HierarchyNodeEntity> subs) {
                                              for (var s in subs) {
                                                ownerItems.add(OwnerDropdownItem(id: s.userId, name: s.fullName, subtitle: s.positionName));
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
                                                  ownerItems.add(OwnerDropdownItem(id: u.userId, name: u.fullName, subtitle: g.groupName));
                                                }
                                                if (g.children.isNotEmpty) addGroupUsers(g.children);
                                              }
                                            }
                                            addGroupUsers(user.groupHierarchy);
                                            void addTeamMembers(List<SalesTeamMemberEntity> members, String teamName) {
                                              for (final m in members) {
                                                if (m.userId != null && !seen.contains(m.userId!)) {
                                                  seen.add(m.userId!);
                                                  ownerItems.add(OwnerDropdownItem(id: m.userId, name: m.fullName, subtitle: '$teamName - ${m.positionName ?? ''}'));
                                                }
                                                if (m.subordinates.isNotEmpty) addTeamMembers(m.subordinates, teamName);
                                              }
                                            }
                                            for (final team in user.salesTeamHierarchy) {
                                              addTeamMembers(team.members, team.salesTeamName);
                                            }
                                          }
                    
                                          final result = await context.pushNamed(
                                            'detailContactDropdown',
                                            extra: ContactDropdownArgs(title: 'Select Owner', items: ownerItems, selectedIds: contactState.ownerIds, isMultiSelect: true),
                                          );
                    
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
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          BlocBuilder<ContactBloc, ContactState>(
                            builder: (context, contactState) {
                              bool isSelected = contactState.startDate != null && contactState.endDate != null;
                              String label = contactState.startDate != null ? (selectedDateLabel ?? 'Create Date') : 'Create Date';
                    
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CustomFilterButton(
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
                                        context.read<ContactBloc>().add(const FetchContactsEvent(startDate: null, endDate: null, isRefresh: true, clearDates: true));
                                        setState(() { selectedDateLabel = null; });
                                      } else {
                                        context.read<ContactBloc>().add(FetchContactsEvent(startDate: result.startDate, endDate: result.endDate, isRefresh: true));
                                        setState(() { selectedDateLabel = result.label; });
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          BlocBuilder<ContactBloc, ContactState>(
                            builder: (context, contactState) {
                              String label = 'Status';
                              bool isSelected = contactState.statusProspectIds != null && contactState.statusProspectIds!.isNotEmpty;
                    
                              if (isSelected) {
                                final statusState = context.read<ProspectStatusBloc>().state;
                    
                                if (statusState.status == ProspectStatusEnum.loaded) {
                                  if (contactState.statusProspectIds!.length == 1) {
                                    final status = statusState.statuses.cast<ProspectStatusEntity?>().firstWhere((e) => e?.statusProspectId == contactState.statusProspectIds!.first, orElse: () => null);
                                    if (status != null) label = status.statusProspectName;
                                  } else {
                                    label = "${contactState.statusProspectIds!.length} Statuses";
                                  }
                                }
                              }
                    
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CustomFilterButton(
                                  label: label,
                                  isSelected: isSelected,
                                  onTap: () async {
                                    final statusState = context.read<ProspectStatusBloc>().state;
                    
                                    if (statusState.status == ProspectStatusEnum.loaded) {
                                      final List<OwnerDropdownItem> statusItems = statusState.statuses.map((e) => OwnerDropdownItem(id: e.statusProspectId, name: e.statusProspectName)).toList();
                    
                                      final result = await context.pushNamed(
                                        'detailContactDropdown',
                                        extra: ContactDropdownArgs(title: 'Select Status Prospect', items: statusItems, selectedIds: contactState.statusProspectIds, isMultiSelect: true),
                                      );
                    
                                      if (result != null) {
                                        final selected = result as List<OwnerDropdownItem>;
                                        context.read<ContactBloc>().add(
                                          FetchContactsEvent(
                                            statusProspectIds: selected.map((e) => e.id!).toList(),
                                            isRefresh: true,
                                            clearStatus: selected.isEmpty,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                    },
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Color(whiteColor),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Color(shadowColor).withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            BlocBuilder<InboxContactBloc, InboxContactState>(
                              builder: (context, state) {
                                if (state is InboxContactLoading) {
                                  return buildInboxTabBarShimmer();
                                }
                                return _buildTabBar();
                              },
                            ),
                            Expanded(child: _buildTabBarView()),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildListPhone({required String phone, required String name, required String image, required Color colorImg, required VoidCallback onTap}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              alignment: Alignment.center,
              child: Row(
                children: [
                  Image.asset(icContactDetailPhone,width: 15,height: 15,color: Color(primaryColor),),
                  SizedBox(width: 5),
                  Text("$phone",style: TextStyle(color: Color(blackColor),fontSize: 16, fontWeight: FontWeight.bold),),
                ],
              ),
            ),
            Row(
              children: [
                Image.asset(icPerson,width: 15,height: 15,color: Color(primaryColor),),
                SizedBox(width: 5),
                Text(name,style: TextStyle(color: Color(grey5Color),fontSize: 14),),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(whiteColor),
              border: Border.all(color: colorImg, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(image,width: 15,height: 15,color: colorImg,),
          ),
        )
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 30,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, 
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        dividerColor: Colors.transparent, 
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          color: Color(primaryColor), 
          borderRadius: BorderRadius.circular(30),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(text: "Personal"),
          Tab(text: "Groups"),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return BlocConsumer<InboxContactBloc, InboxContactState>(
      listenWhen: (prev, curr) => curr is InboxContactError && prev is! InboxContactError,
      listener: (context, state) {
        if (state is InboxContactError) {
          _isFetchingMore = false;
         
          showErrorDialog(context, 'Gagal memuat data inbox');
        }
      },
      builder: (context, state) {
        if (state is InboxContactLoading) {
          return buildInboxShimmer();
        }
        if (state is InboxContactLoaded) {
          _isFetchingMore = state.isFetchingMore;
          return TabBarView(
            children: [
              _buildList(state.contacts, Icons.person, _personalScrollController, state.isFetchingMore),
              _buildList(state.groups, Icons.group, _groupScrollController, state.isFetchingMore),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildList(List<InboxContact> items, IconData icon, ScrollController controller, bool isFetchingMore) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchInbox,
        child: ListView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Text(
                  "Tidak ada data",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInbox,
      child: ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Container(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final item = items[index];

              return RepaintBoundary(child: InkWell(
                onTap: () async {
                  await context.pushNamed(
                    'detailInbox',
                    extra: InboxDetailArgs(
                      data: item,
                      icon: icon,
                    ),
                  );
                  _fetchInbox();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.photo != null && item.photo!.isNotEmpty
                            ? Image.network(
                                item.photo!,
                                width: 46,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarPlaceholder(icon, item.initials),
                              )
                            : _avatarPlaceholder(icon, item.initials),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.ownerName ?? item.jid,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (item.lastConversationDate != null)
                                  Text(
                                    DateHelper().formatInboxDate(item.lastConversationDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                if (item.unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Color(primaryColor),
                                      shape: BoxShape.circle,
                                    ),
                                    
                                    child: Center(
                                      child: Text(
                                        '${NumberHelper.thousands(item.unreadCount)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
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
                    ],
                  ),
                ),
              ));
            },
          ),
        ),
        if (isFetchingMore)
          const ShimmerInboxItem(),
      ],
    ));
  }

  Widget _avatarPlaceholder(IconData icon, String initials) {
    return Container(
      width: 46,
      height: 40,
      decoration: BoxDecoration(
        color: Color(grey10Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(initials, style: TextStyle(color: Color(blue3Color), fontWeight: FontWeight.bold))
            : Icon(icon, size: 24, color: Color(blue3Color)),
      ),
    );
  }
  
  void _showInboxQRDialog(String sessionId) {
    bool hasPopped = false;
    showDialog(
      context: context,
      barrierColor: Colors.black54, 
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), 
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BlocConsumer<WhatsappQrBloc, WhatsappQrState>(
                listener: (context, state) {
                  if (state is WhatsappQrStreaming && state.status == 'CONNECTED' && !hasPopped) {
                    hasPopped = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('WhatsApp Terhubung!'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(dialogContext);
                    this.context.read<WhatsappDeviceBloc>().add(GetWhatsappDevicesEvent());
                    _fetchInbox();
                  }
                  if (state is WhatsappQrError) {
                   
                  }
                },
                builder: (context, state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Scan QR Code for", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(grey10Color)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildQrContent(state),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text("Buka WhatsApp > Perangkat Tertaut > Tautkan Perangkat",textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      SizedBox(height: 16),
                      if (state is WhatsappQrError)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text('Gagal memuat QR code', style: TextStyle(color: Colors.red, fontSize: 10), textAlign: TextAlign.center),
                        ),
                      customButton((){ Navigator.pop(context); }, "Tutup", colorBg: Color(primaryColor), colorText: Color(whiteColor)),
                      SizedBox(height: 10),
                      customButton((){ 
                        context.read<WhatsappQrBloc>().add(StartQrSessionEvent(sessionId));
                      }, "Refresh QR", colorBg: Color(primaryColor), colorText: Color(whiteColor)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQrContent(WhatsappQrState state) {
    if (state is WhatsappQrLoading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    if (state is WhatsappQrStreaming) {
      if (state.qrBase64 != null) {
        return Image.memory(
          base64Decode(state.qrBase64!),
          width: 180,
          height: 180,
          fit: BoxFit.cover,
        );
      }
    }
    return SizedBox(
      width: 180,
      height: 180,
    );
  }
}
