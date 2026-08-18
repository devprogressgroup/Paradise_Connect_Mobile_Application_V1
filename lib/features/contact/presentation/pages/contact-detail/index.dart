import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/drive_image/drive_image.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/share_helper.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/data/models/activity/activity_dashboard.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_prospect_status.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/presentation/pages/contact-form/index.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_event.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_state.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_state.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/upload_attachment_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/upload_attachment_state.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_event.dart';
import 'package:progress_group/features/contact/presentation/state/contact/contact_state.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_state.dart';
import 'package:progress_group/features/inbox/data/arguments/inbox_detail_args.dart';
import 'package:progress_group/features/inbox/domain/entities/inbox_contact_entity.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_block.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_event.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_statte.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_state.dart';
import '../../../../../core/utils/widget/custom_bg_icon.dart';
import '../../../../../core/utils/widget/custom_buttomsheet.dart';
import '../../../../../core/utils/widget/error_dialog.dart';
import 'package:progress_group/features/contact/presentation/widgets/contact_options_sheet.dart';

class ContactDetailPage extends StatefulWidget {
  final ContactDetailArgs args;

  const ContactDetailPage({super.key, required this.args});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage>with TickerProviderStateMixin {
  TextEditingController searchTC = TextEditingController();

  FocusNode searchFN = FocusNode();

  int selectedIndex = 0;

  final tabs = ["Activity", "About", "Attachment"];
  late TabController _tabController;
  int currentTab = 0;
  late AnimationController _headerAnimController;
  late Animation<double> _headerAnim;
  bool _isHeaderHidden = false;
  int _cPage = 1;
  int _gPage = 1;
  final ScrollController _activityScrollController = ScrollController();
  late ContactDetailActivityBloc _contactDetailActivityBloc;
  late ActivityProspectStatusBloc _activityProspectStatusBloc;
  late AttachmentCubit _attachmentCubit;
  late ContactBloc _contactBloc;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('contact_detail');
    _contactDetailActivityBloc = context.read<ContactDetailActivityBloc>();
    _activityProspectStatusBloc = context.read<ActivityProspectStatusBloc>();
    _attachmentCubit = context.read<AttachmentCubit>();
    _contactBloc = context.read<ContactBloc>();
    currentTab = widget.args.initialTab;
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: currentTab,
    );
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _headerAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
    _tabController.addListener(() {
      if (_tabController.index != currentTab) {
        setState(() {
          currentTab = _tabController.index;
          searchTC.clear();
        });
      }
    });
    _activityScrollController.addListener(_onActivityScroll);
    _init();
  }

  void _updateHeaderForScroll(double pixels) {
    if (pixels > 60 && !_isHeaderHidden) {
      _isHeaderHidden = true;
      _headerAnimController.forward();
    } else if (pixels < 20 && _isHeaderHidden) {
      _isHeaderHidden = false;
      _headerAnimController.reverse();
    }
  }

  void _onActivityScroll() {
    if (_activityScrollController.position.pixels >=
        _activityScrollController.position.maxScrollExtent - 200) {
      final contactId = widget.args.dataContact?.contactId;
      if (contactId != null) {
        context.read<ContactDetailActivityBloc>().add(
          FetchActivitiesEvent(contactId: contactId),
        );
      }
    }
  }

  Future<void> _navigateToAddContact(ContactDetailArgs args) async {
    final result = await context.pushNamed(
      'addContact',
      extra: args.copyWith(initialTab: currentTab),
    );
    await _getActivity();
    await _getContactDetail();
    if (result != null && result is int) {
      setState(() {
        currentTab = result;
        _tabController.animateTo(result);
      });
    }
    searchTC.clear();
  }

  void _init() async {
    await _getActivity();
    await _getAttachment();
    await _getContactDetail();
    await _fetchInbox();
  }

  Future<void> _fetchInbox({String? search, bool isLoadMore = false}) async {
    if (!isLoadMore) {
      _cPage = 1;
      _gPage = 1;
    }

    final contactState = context.read<ContactBloc>().state;

    context.read<InboxContactBloc>().add(
      GetInboxContactsEvent(
        search: search ?? searchTC.text,
        cPage: _cPage,
        gPage: _gPage,
        salesExecutiveIds: contactState.ownerIds,
        statusProspectId:
            (contactState.statusProspectIds != null &&
                contactState.statusProspectIds!.isNotEmpty)
            ? contactState.statusProspectIds!.first
            : null,
        startDate: contactState.startDate,
        endDate: contactState.endDate,
        isLoadMore: isLoadMore,
      ),
    );
  }

  Future<void> _getContactDetail() async {
    context.read<AuthBloc>().add(FetchPermissionsEvent(silent: true));
    final contactId = widget.args.dataContact?.contactId;
    if (contactId != null) {
      context.read<ContactBloc>().add(FetchContactDetailEvent(contactId));
    }
  }

  Future<void> _getActivity() async {
    context.read<AuthBloc>().add(FetchPermissionsEvent(silent: true));
    final contactId = widget.args.dataContact?.contactId;
    if (contactId != null) {
      context.read<ContactDetailActivityBloc>().add(
        FetchActivitiesEvent(contactId: contactId, isRefresh: true),
      );
    }
    context.read<ActivityProspectStatusBloc>().add(
      FetchActivityProspectStatusEvent(contactId!),
    );
  }

  Future<void> _getAttachment() async {
    context.read<AuthBloc>().add(FetchPermissionsEvent(silent: true));
    final contactId = widget.args.dataContact?.contactId;
    if (contactId != null) {
      context.read<AttachmentCubit>().fetch(contactId, null);
    }
  }

  Future<void> _deleteAttachment({
    required int contactId,
    required int attachmentId,
  }) async {
    context.read<AttachmentCubit>().delete(
      contactId: contactId,
      attachmentId: attachmentId,
    );
  }

  @override
  void dispose() {
    _contactDetailActivityBloc.add(ResetActivityEvent());
    _activityProspectStatusBloc.add(ResetActivityProspectStatusEvent());
    _attachmentCubit.reset();
    _contactBloc.add(ClearContactDetailEvent());
    _tabController.dispose();
    _headerAnimController.dispose();
    _activityScrollController.dispose();
    searchTC.dispose();
    searchFN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is PermissionsLoaded) setState(() {});
          },
        ),
        BlocListener<ContactBloc, ContactState>(
          listenWhen: (prev, curr) =>
              curr.status == ContactStatus.error && prev.status == ContactStatus.loadingDetail,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Gagal memuat kontak'),
                backgroundColor: Color(redAccentColor),
              ),
            );
            if (context.canPop()) context.pop();
          },
        ),
      ],
      child: Scaffold(body: SafeArea(child: _selectContact())),
    );
  }

  Widget _selectContact() {
    return Scaffold(
      floatingActionButton: (PermissionsHelper.canModifyContacts && (widget.args.dataContact?.canEdit ?? true))
          ? Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                onPressed: () {
                  AnalyticsService.logEvent('contact_detail_add_activity_or_attachment');
                  showCustomBottomSheet(context: context, child: _buildContentBSAdd());
                },
                backgroundColor: Color(primaryColor),
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Color(whiteColor)),
              ),
            )
          : null,
      body: SafeArea(
        child: DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              Container(
                color: Color(whiteColor),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _headerAnim,
                      builder: (context, child) {
                        final v = _headerAnim.value;
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: 1.0 - v,
                            child: Opacity(
                              opacity: (1.0 - v).clamp(0.0, 1.0),
                              child: IgnorePointer(
                                ignoring: v > 0.5,
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                      child: IgnorePointer(
                        ignoring: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          AnalyticsService.logEvent('contact_detail_back');
                                          context.pop();
                                        },
                                        child: Icon(
                                          Icons.arrow_back,
                                          color: Color(primaryColor),
                                          size: 27,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      BlocBuilder<ContactBloc, ContactState>(
                                        builder: (context, contactState) {
                                          if (contactState.status == ContactStatus.loading) {
                                            return buildContactHeaderNameShimmer();
                                          }
                                          final name = contactState.contactDetail?.fullName
                                              ?? widget.args.dataContact?.fullName
                                              ?? '-';
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Contacts",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(blue2Color),
                                                ),
                                              ),
                                              Container(
                                                width: MediaQuery.of(context).size.width * 0.8,
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      BgIcon(
                                        asset: icContactDetailPhone,
                                        onTap: () async {
                                          AnalyticsService.logEvent('contact_detail_call_contact');
                                          final phone = widget.args.dataContact?.primaryPhone;
                                          if (phone != null && phone.isNotEmpty) {
                                            await launchUrl(Uri(scheme: 'tel', path: phone));
                                          }
                                        },
                                      ),
                                      BgIcon(
                                        asset: icContactDetailWA,
                                        onTap: () async {
                                          AnalyticsService.logEvent('contact_detail_chat_whatsapp');
                                          var phone = widget.args.dataContact?.whatsappNumber
                                              ?? widget.args.dataContact?.primaryPhone;
                                          if (phone != null && phone.isNotEmpty) {
                                            phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                                            if (phone.startsWith('0')) {
                                              phone = '62${phone.substring(1)}';
                                            }
                                            await launchUrl(
                                              Uri.parse("https://wa.me/$phone"),
                                              mode: LaunchMode.externalApplication,
                                            );
                                          }
                                        },
                                      ),
                                      BgIcon(
                                        asset: null,
                                        onTap: () {
                                          AnalyticsService.logEvent('contact_detail_open_contact_options');
                                          showCustomBottomSheet(
                                            context: context,
                                            child: _buildContactOptions(
                                              context,
                                              widget.args.dataContact!,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),

                    SizedBox(
                      height: 60,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 24,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(color: Color(grey11Color)),
                          ),
                          Positioned(
                            top: 4,
                            left: 16,
                            right: 16,
                            height: 40,
                            child: _buildTabBar(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: IndexedStack(
                  index: currentTab,
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (currentTab == 0) _updateHeaderForScroll(notification.metrics.pixels);
                        return false;
                      },
                      child: _buildActivityContent(),
                    ),
                    RefreshIndicator(
                      onRefresh: _getContactDetail,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (currentTab == 1) _updateHeaderForScroll(notification.metrics.pixels);
                          return false;
                        },
                        child: ContactFormPage(
                          args: ContactDetailArgs(
                            dataContact: widget.args.dataContact,
                            page: 2,
                          ),
                        ),
                      ),
                    ),
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (currentTab == 2) _updateHeaderForScroll(notification.metrics.pixels);
                        return false;
                      },
                      child: _buildAttachmentContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentBSAdd() {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Log Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 5),
          ContactOptionsSheet.buildIconLink(
            context,
            icContactDetailPhone,
            "Phone",
            () {
              _navigateToAddContact(
                ContactDetailArgs(
                  dataContact: widget.args.dataContact,
                  page: 0,
                  namePage: "Call",
                ),
              );
            },
          ),
          ContactOptionsSheet.buildIconLink(
            context,
            icContactDetailWA,
            "WhatsApp",
            () {
              _navigateToAddContact(
                ContactDetailArgs(
                  dataContact: widget.args.dataContact,
                  page: 1,
                  namePage: "WhatsApp",
                ),
              );
            },
          ),
          ContactOptionsSheet.buildIconLink(
            context,
            icContactDetailReminder,
            "Reminder",
            () {
              _navigateToAddContact(
                ContactDetailArgs(
                  dataContact: widget.args.dataContact,
                  page: 3,
                  namePage: "Reminder",
                ),
              );
            },
          ),
          ContactOptionsSheet.buildIconLink(
            context,
            icContactDetailVisit,
            "Visit",
            () {
              _navigateToAddContact(
                ContactDetailArgs(
                  dataContact: context.read<ContactBloc>().state.contactDetail ?? widget.args.dataContact,
                  page: 4,
                  namePage: "Visit",
                ),
              );
            },
          ),
          ContactOptionsSheet.buildIconLink(
            context,
            icSidebarSalesKit,
            "Update Status Prospect",
            () {
              _navigateToAddContact(
                ContactDetailArgs(
                  dataContact: context.read<ContactBloc>().state.contactDetail ?? widget.args.dataContact,
                  page: 6,
                  namePage: "Update Status Prospect",
                ),
              );
            },
            color: Color(primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    const double height = 40;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Color(grey10Color),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 3;
          final page = currentTab.toDouble();

          List<int> order = [0, 1, 2];
          order.sort((a, b) {
            return (b - page).abs().compareTo((a - page).abs());
          });

          return Stack(
            children: order.map((index) {
              return _buildStackTab(
                index: index,
                left: index * tabWidth,
                tabWidth: tabWidth,
                height: height,
                tabs: tabs,
                page: page,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildStackTab({
    required int index,
    required double left,
    required double tabWidth,
    required double height,
    required List<String> tabs,
    required double page,
  }) {
    final isActive = (page - index).abs() < 0.5;

    return Positioned(
      left: left,
      child: GestureDetector(
        onTap: () {
          AnalyticsService.logEvent('contact_detail_switch_tab');
          setState(() {
            currentTab = index;
            _tabController.animateTo(index);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: tabWidth,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Color(primaryColor) : Color(grey10Color),
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: isActive? [BoxShadow(color: Color(blackColor).withOpacity(0.1),blurRadius: 10,offset: const Offset(0, 2),),]: [],
          ),
          child: Text(
            tabs[index],
            style: TextStyle(
              color: isActive ? Color(whiteColor) : Color(greyShade700),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityContent() {
    return BlocBuilder<ContactDetailActivityBloc, ActivityState>(
      builder: (context, activityState) {
        return BlocBuilder<
          ActivityProspectStatusBloc,
          ActivityProspectStatusState
        >(
          builder: (context, prospectState) {
            return BlocBuilder<WhatsappActivityBloc, WhatsappActivityState>(
              builder: (context, whatsappState) {
                return BlocBuilder<InboxContactBloc, InboxContactState>(
                  builder: (context, inboxState) {
                    return BlocBuilder<
                      WhatsappActivityBloc,
                      WhatsappActivityState
                    >(
                      builder: (context, unreadState) {
                        if (activityState.status == ActivityStatus.loading &&
                            activityState.activities.isEmpty) {
                          return buildActivityShimmer();
                        }

                        List<ActivityTimelineItem> timeline = [];

                        for (var item in activityState.activities) {
                          final date = DateTime.tryParse(item.activityDate);

                          if (date != null) {
                            timeline.add(
                              ActivityTimelineItem(
                                date: date,
                                type: 'activity',
                                data: item,
                              ),
                            );
                          }
                        }

                        for (var item in prospectState.data) {
                          final date = DateTime.tryParse(item.createdAt);

                          if (date != null) {
                            timeline.add(
                              ActivityTimelineItem(
                                date: date,
                                type: 'prospect',
                                data: item,
                              ),
                            );
                          }
                        }

                        for (var item in whatsappState.data) {
                          final date = DateTime.tryParse(item.lastMessageAt);

                          if (date != null) {
                            timeline.add(
                              ActivityTimelineItem(
                                date: date,
                                type: 'whatsapp',
                                data: item,
                              ),
                            );
                          }
                        }

                        if (inboxState is InboxContactLoaded) {
                          for (var item in inboxState.contacts) {
                            final date = DateTime.tryParse(
                              item.lastConversationDate ?? '',
                            );

                            if (date != null) {
                              timeline.add(
                                ActivityTimelineItem(
                                  date: date,
                                  type: 'inbox_contact',
                                  data: item,
                                ),
                              );
                            }
                          }
                        }


                        bool _isCreate(ActivityTimelineItem t) =>t.type == 'activity' && (t.data.activityType == 'Created contact');
                        timeline.sort((a, b) {
                          final aC = _isCreate(a), bC = _isCreate(b);
                          if (aC && !bC) return 1;
                          if (bC && !aC) return -1;
                          return b.date.compareTo(a.date);
                        });

                        final Map<String, List<ActivityTimelineItem>> grouped =
                            {};

                        for (var item in timeline) {
                          final key = DateFormat(
                            'dd MMM yyyy',
                          ).format(item.date);
                          grouped.putIfAbsent(key, () => []);
                          grouped[key]!.add(item);
                        }

                        return RefreshIndicator(
                          onRefresh: _getActivity,
                          child: grouped.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.only(top: 60),
                                      child: Center(
                                        child: Text(
                                          'Tidak ada data aktivitas',
                                          style: TextStyle(color: Color(greyShade500)),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView(
                          controller: _activityScrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          children: [
                            ...grouped.entries.map((entry) {
                              final date = entry.key;
                              final items = entry.value.where((e) {
                                if (e.type == 'inbox_contact') {
                                  final item = e.data;
                                  return item.crmContactId ==
                                      widget.args.dataContact?.contactId;
                                }
                                return true;
                              }).toList();

                              if (items.isEmpty) return const SizedBox();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    children: items.map((item) {
                                      if (item.type == 'activity') {
                                        return ActivityItem(
                                          item: item.data,
                                          activityColor: Color(purpleColor),
                                        );
                                      } else if (item.type == 'prospect') {
                                        return _prospectItem(item.data);
                                      } else if (item.type == 'inbox_contact') {
                                        return _inboxContactItem(item.data);
                                      } else if (item.type == 'contact_date') {
                                        return _contactDateItem(
                                          item.data['label'] as String,
                                          item.date,
                                        );
                                      }
                                      return const SizedBox();
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).toList(),
                          ],
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
      },
    );
  }

  Widget _inboxContactItem(InboxContact item) {
    if (item.crmContactId != widget.args.dataContact?.contactId) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: () {
        AnalyticsService.logEvent('contact_detail_open_whatsapp_chat_item');
        context.pushNamed('detailInbox', extra: InboxDetailArgs(data: item));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(greyShade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(successColor), width: 5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Chat with ${item.ownerName ?? '-'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(
                        DateTime.parse(item.lastConversationDate ?? '-'),
                      ),
                      style: TextStyle(fontSize: 11),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        "${item.lastMessage ?? '-'}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prospectItem(ActivityProspectStatusEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(warningColor), width: 5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${item.projectName}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'HH:mm',
                    ).format(DateTime.parse(item.createdAt)),
                    style: TextStyle(fontSize: 11),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      (item.previousStatusName == null || item.previousStatusName!.isEmpty)
                          ? "Status changed to ${item.statusValue ?? ''} - ${item.statusName}"
                          : "Status changed from ${item.previousStatusValue ?? ''} - ${item.previousStatusName ?? ''} to ${item.statusValue ?? ''} - ${item.statusName}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactDateItem(String label, DateTime date) {
    final typeColors = <String, int>{
      'Appt': purpleColor,
      'Reserve': purpleColor,
      'SP': purpleColor,
      'Akad': purpleColor,
      'Lost': purpleColor,
    };
    final color = typeColors[label] ?? infoColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(color), width: 5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(date),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          customSearchField(controller: searchTC, focusNode: searchFN),
          SizedBox(height: 9),
          if (PermissionsHelper.canUploadAttachment && (widget.args.dataContact?.canEdit ?? true))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(whiteColor),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(blackColor).withOpacity(0.08),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                BgIcon(
                  asset: icUpload,
                  onTap: PermissionsHelper.canUploadAttachment ? () {
                    AnalyticsService.logEvent('contact_detail_upload_attachment');
                    _navigateToAddContact(
                      ContactDetailArgs(
                        dataContact: widget.args.dataContact,
                        page: 5,
                        namePage: "Attachment",
                      ),
                    );
                  } : null,
                  color: PermissionsHelper.canUploadAttachment ? Color(primaryColor) : Color(greyShade500),
                ),
                SizedBox(width: 10),
                Column(
                  children: [
                    Text(
                      "Add New File",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PermissionsHelper.canUploadAttachment ? Color(primaryColor) : Color(greyShade500),
                      ),
                    ),
                    Text(
                      "upload new file",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: PermissionsHelper.canUploadAttachment ? Color(grey5Color) : Color(greyShade500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            // Error upload TIDAK ditampilkan di sini — halaman ini cuma nyimak sukses buat
            // refresh list lampiran; yang benar-benar submit SubmitAttachmentEvent (dan yang
            // seharusnya nampilin pesan error-nya) adalah ContactAddPage.
            child: BlocListener<UploadAttachmentBloc, UploadAttachmentState>(
              listenWhen: (prev, curr) => curr is UploadAttachmentSuccess,
              listener: (context, state) {
                context.read<AttachmentCubit>().fetch(
                  widget.args.dataContact!.contactId!,
                  widget.args.dataContact!.dealId,
                );
              },
              child: RefreshIndicator(
                onRefresh: _getAttachment,
                child: BlocConsumer<AttachmentCubit, AttachmentState>(
                  listenWhen: (prev, curr) => curr is AttachmentError && prev is! AttachmentError,
                  listener: (context, state) {
                    if (state is AttachmentError) {
                      showErrorDialog(context, state.message);
                    }
                  },
                  builder: (context, state) {
                    if (state is AttachmentLoading) {
                      return buildAttachmentShimmer();
                    }

                    if (state is AttachmentLoaded) {
                      final list = state.data;

                      if (list.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 300,
                              child: Center(child: Text("No attachment")),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return GestureDetector(
                            onTap: () {
                              AnalyticsService.logEvent('contact_detail_open_attachment');
                              if (item.attachmentUrl.isNotEmpty) {
                                AnalyticsService.logEvent('contact_detail_view_attachment_webview');
                                context.pushNamed(
                                  'attachmentWebView',
                                  extra: item.attachmentUrl,
                                );
                              } else {
                                _navigateToAddContact(
                                  ContactDetailArgs(
                                    page: 6,
                                    dataContact: ContactEntity(
                                      contactId: widget.args.dataContact!.contactId,
                                      fullName:widget.args.dataContact?.fullName,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Color(whiteColor),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(blackColor).withOpacity(0.08),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Color(greyShade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: DriveImage(
                                        url: item.attachmentUrl,
                                        width: 58,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        onTap: () {
                                          if (item.attachmentUrl.isNotEmpty) {
                                            AnalyticsService.logEvent('contact_detail_view_attachment_webview');
                                            context.pushNamed('attachmentWebView', extra: item.attachmentUrl);
                                          }
                                        },
                                        errorWidget: Container(
                                          width: 58,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Color(whiteColor),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: Color(primaryColor)),
                                          ),
                                          child: Icon(Icons.picture_as_pdf, color: Color(primaryColor)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:CrossAxisAlignment.start,
                                    mainAxisAlignment:MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.5,
                                        child: Text(
                                          item.attachmentTypeName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        item.createDatetime.toString(),
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      Container(
                                        width: 200,
                                        child: Text(
                                          item.attachmentNote,
                                          maxLines: 1,
                                          overflow:TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),

                                  Spacer(),
                                  if ((PermissionsHelper.canEditAttachmentItem && (widget.args.dataContact?.canEdit ?? true)) ||
                                      (PermissionsHelper.canDeleteAttachmentItem && (widget.args.dataContact?.canDelete ?? true)))
                                  PopupMenuButton<String>(
                                    enabled: item.attachmentTypeId != 12,
                                    icon: Container(
                                      height: 44,
                                      width: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Color(grey11Color),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(Icons.more_vert, size: 30),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _navigateToAddContact(
                                          ContactDetailArgs(
                                            dataContact: widget.args.dataContact,
                                            dataAttachment: item,
                                            page: 7,
                                            namePage: "Attachment",
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        _showDeleteDialog(context, item);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (PermissionsHelper.canEditAttachmentItem && (widget.args.dataContact?.canEdit ?? true))
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.edit, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                      if (PermissionsHelper.canDeleteAttachmentItem && (widget.args.dataContact?.canDelete ?? true))
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.delete, size: 18, color: Color(redAccentColor)),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return SizedBox();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOptions(BuildContext context, ContactEntity contact) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconLink(context, icEdit, "Edit Contact", () async {
            final result = await context.pushNamed(
              'formContact',
              extra: ContactDetailArgs(
                dataContact: contact,
                page: 1,
                initialTab: currentTab,
              ),
            );
            if (result != null && result is int) {
              setState(() {
                currentTab = result;
                _tabController.animateTo(result);
              });
            }
          }, hidden: !(PermissionsHelper.canEditContact && (contact.canEdit ?? true))),
          _buildIconLink(context, icDelete, "Delete Contact", () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Confirm'),
                content: Text('Delete this contact?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      AnalyticsService.logEvent('contact_detail_delete_contact_confirm');
                      Navigator.pop(ctx);
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      AnalyticsService.logEvent('contact_detail_delete_contact_confirm');
                      context.replace("/contact");
                      context.pop();
                      context.read<ContactBloc>().add(
                        DeleteContactEvent(contact.contactId!),
                      );
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

 void _showImagePreview(
  BuildContext context,
  List<String> imageUrls,
  int initialIndex,
) {
  final screenSize = MediaQuery.of(context).size;

  showDialog(
    context: context,
    barrierColor: Color(blackColor).withAlpha(87),
    builder: (dialogContext) {
      int currentIndex = initialIndex;

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Color(transparentColor),
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenSize.width - 20,
                    maxHeight: screenSize.height - 80,
                  ),
                  child: InteractiveViewer(
                    child: DriveImage(
                      url: imageUrls[currentIndex],
                      width: screenSize.width - 20,
                      height: screenSize.height - 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                if (currentIndex > 0)
                  Positioned(
                    left: 10,
                    child: IconButton(
                      iconSize: 40,
                      color: Color(whiteColor),
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        AnalyticsService.logEvent('contact_detail_image_preview_prev');
                        setState(() {
                          currentIndex--;
                        });
                      },
                    ),
                  ),

                if (currentIndex < imageUrls.length - 1)
                  Positioned(
                    right: 10,
                    child: IconButton(
                      iconSize: 40,
                      color: Color(whiteColor),
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        AnalyticsService.logEvent('contact_detail_image_preview_next');
                        setState(() {
                          currentIndex++;
                        });
                      },
                    ),
                  ),

                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(whiteColor),
                      size: 30,
                    ),
                    onPressed: () {
                      AnalyticsService.logEvent('contact_detail_close_image_preview');
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),

                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(blackColor).withAlpha(54),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${currentIndex + 1} / ${imageUrls.length}',
                      style: const TextStyle(
                        color: Color(whiteColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  void _showDeleteDialog(BuildContext context, item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Attachment"),
        content: Text("Are you sure want to delete this file?"),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              AnalyticsService.logEvent('contact_detail_delete_attachment_confirm');
              context.pop();
              _deleteAttachment(
                contactId: item.contactId,
                attachmentId: item.contactAttachmentId,
              );
            },
            child: Text("Delete", style: TextStyle(color: Color(redAccentColor))),
          ),
        ],
      ),
    );
  }
}


class ActivityItem extends StatefulWidget {
  final ActivityEntity item;
  final Color activityColor;

  const ActivityItem({
    super.key,
    required this.item,
    required this.activityColor,
  });

  @override
  State<ActivityItem> createState() => _ActivityItemState();
}

class _ActivityItemState extends State<ActivityItem> {
  bool imageError = false;

  final ScrollController _scrollController = ScrollController();

  bool isAtStart = true;
  bool isAtEnd = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final offset = _scrollController.offset;

      setState(() {
        isAtStart = offset <= 0;
        isAtEnd = offset >= maxScroll;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;

      setState(() {
        isAtStart = true;
        isAtEnd = maxScroll == 0;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    AnalyticsService.logEvent('contact_detail_scroll_gallery_left');
    final newOffset = (_scrollController.offset - 250).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    AnalyticsService.logEvent('contact_detail_scroll_gallery_right');
    final newOffset = (_scrollController.offset + 250).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _arrowButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Color(blackColor).withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Color(whiteColor), size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTap: () {
        if (item.statusFollow == 1) return;

        AnalyticsService.logEvent('contact_detail_mark_status_follow');

        final type = item.activityType.toLowerCase();
        int page = 6;
        String namePage = "Update Status Prospect";

        if (type.contains('call')) {
          page = 0;
          namePage = "Call";
        } else if (type.contains('whatsapp')) {
          page = 1;
          namePage = "WhatsApp";
        } else if (type.contains('reminder')) {
          page = 3;
          namePage = "Reminder";
        } else if (type.contains('task')) {
          page = 3;
          namePage = "Task";
        } else if (type.contains('visit')) {
          page = 4;
          namePage = "Visit";
        }

        final parentState = context.findAncestorStateOfType<_ContactDetailPageState>();
        if (parentState != null) {
          parentState._navigateToAddContact(
            ContactDetailArgs(
              page: page,
              namePage: namePage,
              dataActivity: widget.item,
              buttonLabel: 'Complete',
              dataContact: parentState.widget.args.dataContact,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           if(item.activityType == 'Created contact') _noteCreate(context, item),
           if(item.activityType != 'Created contact')
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: item.statusFollow == 1 ? Color(greyShade500) : Color(purpleColor),
                          width: 5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.activityType,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: item.statusFollow == 1 ? Color(greyShade500) : null,
                            decoration: item.statusFollow == 1 ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'HH:mm',
                          ).format(DateTime.parse(item.activityDate)),
                          style: TextStyle(fontSize: 11),
                        ),
                        if (item.notes != null)
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              item.notes!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (item.statusFollow == 1)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color(greenMaterialColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color(greenMaterialColor), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Color(greenMaterialColor), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Complete',
                          style: TextStyle(
                            color: Color(greenMaterialColor),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (item.imagePaths != null && item.imagePaths!.isNotEmpty)
              Container(
                height: 200,
                margin: const EdgeInsets.only(top: 10),
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: item.imagePaths!.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: DriveImage(
                              url: item.imagePaths![index],
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                              onTap: () {
                                final parentState = context .findAncestorStateOfType<   _ContactDetailPageState >();
                                if (parentState != null) {
                                  parentState._showImagePreview(
                                    context,
                                    item.imagePaths!,
                                    index,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    if (!isAtStart)
                      Positioned(
                        left: 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _scrollLeft,
                            child: _arrowButton(Icons.arrow_back_ios),
                          ),
                        ),
                      ),

                    if (!isAtEnd)
                      Positioned(
                        right: 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _scrollRight,
                            child: _arrowButton(Icons.arrow_forward_ios),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
Widget _noteCreate(BuildContext context,ActivityEntity item){
  return Row(
    children: [
      Expanded(
        child: Container(
          padding: EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(purpleColor), width: 5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${item.activityType}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                DateFormat(
                  'HH:mm',
                ).format(DateTime.parse(item.activityDate)),
                style: TextStyle(fontSize: 11),
              ),
              if (item.notes != null)
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    item.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
}

