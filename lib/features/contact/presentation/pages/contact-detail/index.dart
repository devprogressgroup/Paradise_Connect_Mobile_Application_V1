import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
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
import '../../../../../core/utils/widget/custom_bg_icon.dart';
import '../../../../../core/utils/widget/custom_buttomsheet.dart';
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
  bool _hideHeader = false;
  int _cPage = 1;
  int _gPage = 1;
  final ScrollController _activityScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentTab = widget.args.initialTab;
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: currentTab,
    );
    _tabController.addListener(() {
      if (_tabController.index != currentTab) {
        setState(() {
          currentTab = _tabController.index;
          searchTC.clear();
          _hideHeader = false;
        });
      }
    });
    _activityScrollController.addListener(_onActivityScroll);
    _init();
  }

  void _onActivityScroll() {
    if (_activityScrollController.position.pixels >=
        _activityScrollController.position.maxScrollExtent - 200) {
      final contactId = widget.args.dataContact?.contactId;
      if (contactId != null) {
        context.read<ActivityBloc>().add(
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
    final contactId = widget.args.dataContact?.contactId;
    if (contactId != null) {
      context.read<ContactBloc>().add(FetchContactDetailEvent(contactId));
    }
  }

  Future<void> _getActivity() async {
    final contactId = widget.args.dataContact?.contactId;
    if (contactId != null) {
      context.read<ActivityBloc>().add(
        FetchActivitiesEvent(contactId: contactId, isRefresh: true),
      );
    }
    context.read<ActivityProspectStatusBloc>().add(
      FetchActivityProspectStatusEvent(contactId!),
    );
  }

  Future<void> _getAttachment() async {
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
    context.read<ActivityBloc>().add(ResetActivityEvent());
    context.read<ActivityProspectStatusBloc>().add(
      ResetActivityProspectStatusEvent(),
    );
    context.read<AttachmentCubit>().reset();
    context.read<ContactBloc>().add(ClearContactDetailEvent());
    _tabController.dispose();

    _activityScrollController.dispose();
    searchTC.dispose();
    searchFN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: _selectContact()));
  }

  Widget _selectContact() {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          onPressed: () {
            showCustomBottomSheet(
              context: context,
              child: _buildContentBSAdd(),
            );
          },
          backgroundColor: Color(primaryColor),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: _hideHeader ? 65 : 210,
                child: Stack(
                  children: [
                    if (!_hideHeader)
                    Positioned(
                      top: 0,
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        color: Color(whiteColor),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Color(primaryColor),
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                BlocBuilder<ContactBloc, ContactState>(
                                  builder: (context, contactState) {
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
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                BgIcon(
                                  asset: icContactDetailPhone,
                                  onTap: () async {
                                    final phone =
                                        widget.args.dataContact?.primaryPhone;
                                    if (phone != null && phone.isNotEmpty) {
                                      final Uri launchUri = Uri(
                                        scheme: 'tel',
                                        path: phone,
                                      );
                                      await launchUrl(launchUri);
                                    }
                                  },
                                ),
                                BgIcon(
                                  asset: icContactDetailWA,
                                  onTap: () async {
                                    var phone =widget.args.dataContact?.whatsappNumber ??widget.args.dataContact?.primaryPhone;
                                    if (phone != null && phone.isNotEmpty) {
                                      phone = phone.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      );
                                      if (phone.startsWith('0')) {
                                        phone = '62${phone.substring(1)}';
                                      }
                                      final Uri whatsappUri = Uri.parse(
                                        "https://wa.me/$phone",
                                      );
                                      await launchUrl(
                                        whatsappUri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                ),
                                BgIcon(
                                  asset: null,
                                  onTap: () {
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
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: _hideHeader ? 25 : 50,
                      left: 16,
                      right: 16,
                      child: Transform.translate(
                        offset: const Offset(0, 25),
                        child: _buildTabBar(),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: IndexedStack(
                  index: currentTab,
                  children: [
                    _buildActivityContent(),
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (currentTab == 1) {
                          final shouldHide = notification.metrics.pixels > 50;
                          if (_hideHeader != shouldHide) {
                            setState(() => _hideHeader = shouldHide);
                          }
                        }
                        return false;
                      },
                      child: ContactFormPage(
                        args: ContactDetailArgs(
                          dataContact: widget.args.dataContact,
                          page: 2,
                        ),
                      ),
                    ),
                    _buildAttachmentContent(),
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
                "Add...",
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
            icContactDetailMeeting,
            "Meeting",
            () {
              _navigateToAddContact(
                ContactDetailArgs(
                  dataContact: widget.args.dataContact,
                  page: 2,
                  namePage: "Meeting",
                ),
              );
            },
          ),
          ContactOptionsSheet.buildIconLink(
            context,
            icContactDetailReminder,
            "Task",
            () {
              _navigateToAddContact(
                ContactDetailArgs(
                  dataContact: widget.args.dataContact,
                  page: 3,
                  namePage: "Task",
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
                  dataContact: widget.args.dataContact,
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
                  dataContact: widget.args.dataContact,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Color(grey10Color),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 2.6;
            final page = currentTab.toDouble();

            List<int> order = [0, 1, 2];
            order.sort((a, b) {
              return (b - page).abs().compareTo((a - page).abs());
            });

            return Stack(
              children: order.map((index) {
                return _buildStackTab(
                  index: index,
                  left: index * (tabWidth - 25),
                  tabWidth: tabWidth,
                  height: height,
                  tabs: tabs,
                  page: page,
                );
              }).toList(),
            );
          },
        ),
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
          setState(() {
            currentTab = index;
            _tabController.animateTo(index);
            _hideHeader = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: tabWidth,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive? Color(primaryColor): (index == 1 ? Color(grey8Color) : Color(grey10Color)),
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: isActive? [BoxShadow(color: Colors.black.withOpacity(0.1),blurRadius: 10,offset: const Offset(0, 2),),]: [],
          ),
          child: Text(
            tabs[index],
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityContent() {
    return BlocBuilder<ActivityBloc, ActivityState>(
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
                        // =========================
                        // LOADING
                        // =========================
                        if (activityState.status == ActivityStatus.loading &&
                            activityState.activities.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // =========================
                        // MERGE TIMELINE
                        // =========================
                        List<ActivityTimelineItem> timeline = [];

                        // =========================
                        // ACTIVITY
                        // =========================
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

                        // =========================
                        // PROSPECT
                        // =========================
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

                        // =========================
                        // WHATSAPP
                        // =========================
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

                        // =========================
                        // INBOX CONTACT
                        // =========================
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

                        // =========================
                        // SORT DESC
                        // =========================
                        timeline.sort((a, b) => b.date.compareTo(a.date));

                        // =========================
                        // GROUP BY DATE
                        // =========================
                        final Map<String, List<ActivityTimelineItem>> grouped =
                            {};

                        for (var item in timeline) {
                          final key = DateFormat(
                            'dd MMM yyyy',
                          ).format(item.date);

                          grouped.putIfAbsent(key, () => []);

                          grouped[key]!.add(item);
                        }

                        // =========================
                        // UI
                        // =========================
                        return ListView(
                          controller: _activityScrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          children: [
                            // TIMELINE ITEMS
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
                                      }
                                      return const SizedBox();
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).toList(),
                          ],
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
        context.pushNamed('detailInbox', extra: InboxDetailArgs(data: item));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
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
                      "Status changed from ${item.previousStatusValue ?? ''} - ${item.previousStatusName ?? ''}  to ${item.statusValue ?? ''} - ${item.statusName} ",
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

  Widget _buildAttachmentContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          customSearchField(controller: searchTC, focusNode: searchFN),
          SizedBox(height: 9),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(whiteColor),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                BgIcon(
                  asset: icUpload,
                  onTap: () {
                    _navigateToAddContact(
                      ContactDetailArgs(
                        dataContact: widget.args.dataContact,
                        page: 5,
                        namePage: "Attachment",
                      ),
                    );
                  },
                  color: Color(primaryColor),
                ),
                SizedBox(width: 10),
                Column(
                  children: [
                    Text(
                      "Add New File",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(primaryColor),
                      ),
                    ),
                    Text(
                      "upload new file",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(grey5Color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocListener<UploadAttachmentBloc, UploadAttachmentState>(
              listener: (context, state) {
                if (state is UploadAttachmentSuccess) {
                  context.read<AttachmentCubit>().fetch(
                    widget.args.dataContact!.contactId!,
                    widget.args.dataContact!.dealId,
                  );
                }

                if (state is UploadAttachmentError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              child: RefreshIndicator(
                onRefresh: _getAttachment,
                child: BlocBuilder<AttachmentCubit, AttachmentState>(
                  builder: (context, state) {
                    if (state is AttachmentLoading) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (state is AttachmentLoaded) {
                      final list = state.data;

                      if (list.isEmpty) {
                        return Center(child: Text("No attachment"));
                      }

                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return GestureDetector(
                            onTap: () {
                              if (item.attachmentUrl.isNotEmpty) {
                                context.pushNamed(
                                  'attachmentWebView',
                                  extra: item.attachmentUrl,
                                );
                              } else {
                                _navigateToAddContact(
                                  ContactDetailArgs(
                                    page: 6,
                                    dataContact: ContactEntity(
                                      contactId:
                                          widget.args.dataContact!.contactId,
                                      fullName:
                                          widget.args.dataContact?.fullName,
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
                                    color: Colors.black.withOpacity(0.08),
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
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        convertDriveUrl(item.attachmentUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: 58,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: Color(whiteColor),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Color(primaryColor),
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.picture_as_pdf,
                                                  color: Color(primaryColor),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.attachmentTypeName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        item.createDatetime.toString(),
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        item.attachmentNote,
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),

                                  Spacer(),
                                  PopupMenuButton<String>(
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
                                            dataContact:
                                                widget.args.dataContact,
                                            dataAttachment: item,
                                            page: 6,
                                            namePage: "Attachment",
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        _showDeleteDialog(context, item);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.red,
                                            ),
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
                    if (state is AttachmentError) {
                      return Center(child: Text(state.message));
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
          }),
          _buildIconLink(context, icDelete, "Delete Contact", () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Confirm'),
                content: Text('Delete this contact?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
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
          }),
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
  }) {
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
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Color(blue2Color),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(dialogContext),
              child: InteractiveViewer(
                child: Image.network(
                  convertDriveUrl(imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
          ],
        ),
      ),
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
              context.pop();
              _deleteAttachment(
                contactId: item.contactId,
                attachmentId: item.contactAttachmentId,
              );
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

String convertDriveUrl(String url) {
  final uri = Uri.parse(url);
  final id = uri.pathSegments[2];
  return 'https://drive.google.com/uc?export=view&id=$id';
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

    // delay biar posisi awal kebaca
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
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTap: () {
        final type = item.activityType.toLowerCase();
        int page = 6;
        String namePage = "Update Status Prospect";

        if (type.contains('call')) {
          page = 0;
          namePage = "Call";
        } else if (type.contains('whatsapp')) {
          page = 1;
          namePage = "WhatsApp";
        } else if (type.contains('meeting')) {
          page = 2;
          namePage = "Meeting";
        } else if (type.contains('task')) {
          page = 3;
          namePage = "Task";
        } else if (type.contains('visit')) {
          page = 4;
          namePage = "Visit";
        }

        // Find the parent state to get dataContact
        final parentState = context.findAncestorStateOfType<_ContactDetailPageState>();
        if (parentState != null) {
          parentState._navigateToAddContact(
            ContactDetailArgs(
              page: page,
              namePage: namePage,
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
            /// ================= HEADER =================
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
                        left: BorderSide(color: Color(purpleColor), width: 5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.activityType,
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
            ),

            /// ================= IMAGES =================
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
                          child: GestureDetector(
                            onTap: () {
                              // Find the parent state to call _showImagePreview
                              final parentState = context
                                  .findAncestorStateOfType<
                                    _ContactDetailPageState
                                  >();
                              if (parentState != null) {
                                parentState._showImagePreview(
                                  context,
                                  item.imagePaths![index],
                                );
                              }
                            },
                            child: ClipRRect(
                              child: Image.network(
                                convertDriveUrl(item.imagePaths![index]),
                                fit: BoxFit.fill,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    /// 🔥 LEFT ARROW
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

                    /// 🔥 RIGHT ARROW
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
                "${item.activityType} on ${DateHelper.formatDateTimeShort(DateTime.parse(item.activityDate))}",
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

