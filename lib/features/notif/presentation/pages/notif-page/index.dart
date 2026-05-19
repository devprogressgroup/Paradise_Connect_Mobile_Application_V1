import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/features/inbox/data/arguments/inbox_detail_args.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_event.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_state.dart';
import 'package:progress_group/features/inbox/domain/entities/inbox_contact_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/activity/whatsapp_activity_entity.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_event.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_state.dart';
import 'package:progress_group/app/router.dart';

class NotifPage extends StatefulWidget {
  const NotifPage({super.key});

  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  final Set<int> _completedActivityIds = {};
  String _selectedActivityType = 'All';

  final List<String> _activityTypes = ['All', 'WhatsApp', 'Call', 'Visit', 'Meeting', 'Task'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    context.read<NotifActivityBloc>().add(
      FetchActivitiesEvent(
        activityType: _selectedActivityType == 'All' ? null : _selectedActivityType.toLowerCase(),
        isRefresh: true,
      ),
    );
    
    // Fetch all unread summaries (contactId 0)
    context.read<WhatsappActivityBloc>().add(const FetchWhatsappUnreadSummaryEvent(0));
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
      child: BlocListener<NotifActivityBloc, ActivityState>(
        listener: (context, state) {
          if (state.status == ActivityStatus.loaded && state.activities.isNotEmpty) {
            final ids = state.activities.map((a) => a.activityId).toList();
            context.read<NotifActivityBloc>().add(MarkActivitiesAsSeenEvent(ids));
          }
        },
        child: BlocBuilder<NotifActivityBloc, ActivityState>(
          builder: (context, state) {
            final isLoading = state.status == ActivityStatus.loading;
            final activities = state.activities;

            return Stack(
              children: [
                Column(
                  children: [
                    customHeader(context, "Notifikasi", isBack: true, colorBack: Color(primaryColor)),
                    const SizedBox(height: 16),

                    /// FILTER
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: _activityTypes.map((type) {
                          final isSelected = _selectedActivityType == type;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                if (_selectedActivityType != type) {
                                  setState(() => _selectedActivityType = type);
                                  _loadData();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Color(primaryColor) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Color(primaryColor)),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Color(primaryColor),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// LIST
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: isLoading && activities.isEmpty
                            ? buildNotifShimmer()
                            : activities.isEmpty
                            ? RefreshIndicator(
                                onRefresh: _onRefresh,
                                child: ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(child: Text("Tidak ada notifikasi aktivitas")),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _onRefresh,
                                child: ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  children: [
                                    const SizedBox(height: 10),
                                    
                                    /// WHATSAPP UNREAD SUMMARY
                                    if (_selectedActivityType == 'All' || _selectedActivityType == 'WhatsApp')
                                      BlocBuilder<WhatsappActivityBloc, WhatsappActivityState>(
                                        builder: (context, whatsappState) {
                                          if (whatsappState.status == WhatsappUnreadSummaryStatus.loaded && whatsappState.data.isNotEmpty) {
                                            return Column(
                                              children: whatsappState.data.map((item) => _whatsappUnreadItem(item)).toList(),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),

                                    /// ACTIVITY ITEMS
                                    ...List.generate(activities.length, (index) {
                                      final activity = activities[index];

                                    final isCompleted = _completedActivityIds.contains(activity.activityId);
                                    final type = activity.activityType.toLowerCase();

                                    final isWhatsApp = type.contains('whatsapp');
                                    final isCall = type.contains('call');
                                    final isMeeting = type.contains('meeting');
                                    final isVisit = type.contains('visit');
                                    final isTask = type.contains('task');

                                    return GestureDetector(
                                      onTap: () async {
                                        int page = 6;
                                        String namePage = "Update Status Prospect";

                                        if (isCall) { page = 0; namePage = "Call"; }
                                        else if (isWhatsApp) { page = 1; namePage = "WhatsApp"; }
                                        else if (isMeeting) { page = 2; namePage = "Meeting"; }
                                        else if (isTask) { page = 3; namePage = "Task"; }
                                        else if (isVisit) { page = 4; namePage = "Visit"; }

                                        await context.pushNamed(
                                          'addContact',
                                          extra: ContactDetailArgs(
                                            page: page,
                                            namePage: namePage,
                                            dataActivity: activity,
                                            dataContact: ContactEntity(
                                              contactId: activity.contactId,
                                              fullName: activity.contactName,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  isCompleted ? Icons.check_circle : Icons.check_circle_outline_rounded,
                                                  color: isCompleted ? Colors.green : Color(primaryColor),
                                                  size: 40,
                                                ),
                                                const SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      activity.activityType,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(blackColor),
                                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                      ),
                                                    ),
                                                    Text(
                                                      activity.contactName??'',
                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color)),
                                                    ),
                                                    Text(
                                                      activity.nextFollowUpDate != null
                                                          ? DateHelper.formatToIndonesian(DateTime.parse(activity.nextFollowUpDate!))
                                                          : "No follow-up date",
                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            isWhatsApp
                                                ? Image.asset(icContactDetailWA, width: 30)
                                                : isMeeting
                                                    ? Image.asset(icContactDetailMeeting, width: 30)
                                                    : isVisit
                                                        ? Image.asset(icContactDetailVisit, width: 30)
                                                        : Icon(isCall ? Icons.phone_outlined : Icons.event_note_outlined, color: Color(primaryColor), size: 30),
                                          ],
                                        ),
                                      ));
                                    
          })],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                if (isLoading && activities.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: buildNotifShimmer(),
                  ),
              ],
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _whatsappUnreadItem(WhatsappUnreadSummaryEntity item) {
    return GestureDetector(
      onTap: () {
        AppRouter.rootNavigatorKey.currentContext!.pushNamed(
          'detailInbox',
          extra: InboxDetailArgs(
            data: InboxContact(
              id: item.contactId ?? 0,
              name: item.contactName,
              jid: item.jid,
              isGroup: item.jid.endsWith('@g.us'),
              initials: item.contactName.isNotEmpty ? item.contactName[0] : '?',
              sessionCode: item.sessionId,
              photo: item.photoProfile,
            ),
            icon: Icons.person,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 5,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  children: [
                    TextSpan(
                      text: item.contactName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: " mengirim "),
                    TextSpan(
                      text: "${item.unreadCount} pesan belum dibaca",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const TextSpan(text: "."),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}