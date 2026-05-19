import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_event.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_state.dart';
import 'package:progress_group/features/inbox/data/arguments/inbox_detail_args.dart';
import 'package:progress_group/features/inbox/domain/entities/inbox_contact_entity.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final Set<int> _completedActivityIds = {};
  String _selectedActivityType = 'All';
  final List<String> _activityTypes = ['All', 'WhatsApp', 'Call', 'Visit', 'Meeting', 'Task'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    context.read<ActivityBloc>().add(
      FetchActivitiesEvent(
        followUpStartDate: todayStr,
        followUpEndDate: todayStr,
        activityType: _selectedActivityType == 'All' ? null : _selectedActivityType.toLowerCase(),
        isRefresh: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            final isLoading = state.status == ActivityStatus.loading;

            return Stack(
              children: [
                Column(
                  children: [
                    customHeader(context, "Upcoming Task", isBack: true, colorBack: Color(primaryColor)),
                    const SizedBox(height: 16),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildComingTask(state),
                      ),
                    ),
                  ],
                ),

                /// 🔥 GLOBAL LOADING OVERLAY
                AnimatedOpacity(
                  duration: Duration(milliseconds: 200),
                  opacity: isLoading && state.activities.isNotEmpty ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !(isLoading && state.activities.isNotEmpty),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildComingTask(ActivityState state) {
    final activities = state.activities;
    final isLoading = state.status == ActivityStatus.loading;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Tasks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),

        SizedBox(height: 12),

        /// 🔥 FILTER
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _activityTypes.map((type) {
              final isSelected = _selectedActivityType == type;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    if (_selectedActivityType != type) {
                      setState(() {
                        _selectedActivityType = type;
                      });
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
                    child: Text(type, style: TextStyle(color: isSelected ? Colors.white : Color(primaryColor), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 16),

        /// 🔥 LIST
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3)),
              ],
            ),

            child: isLoading && activities.isEmpty
                ? buildTaskShimmer()
                : activities.isEmpty
                ? Center(child: Text("No upcoming tasks for today"))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        final isCompleted = _completedActivityIds.contains(activity.activityId);
                        final isWhatsApp = activity.activityType.toLowerCase().contains('whatsapp');
                        final isCall = activity.activityType.toLowerCase().contains('call');

                        return GestureDetector(
                          onTap: () async {
                            if (isWhatsApp) {
                              if (activity.waId != null && activity.jid != null && activity.sessionCode != null) {
                                context.pushNamed('detailInbox',
                                  extra: InboxDetailArgs(
                                    data: InboxContact(
                                      id: activity.waId!,
                                      name: activity.contactName ?? 'Unknown',
                                      jid: activity.jid!,
                                      isGroup: activity.isGroup ?? false,
                                      initials: activity.initials ?? '?',
                                      sessionCode: activity.sessionCode!,
                                    ),
                                    icon: Icons.person,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Missing message history'), backgroundColor: Colors.red),
                                );
                              }
                            } else if (isCall) {
                              final Uri telLaunchUri = Uri(scheme: 'tel', path: activity.phoneNumber);
                              if (await canLaunchUrl(telLaunchUri)) {
                                await launchUrl(telLaunchUri);
                              }
                            }

                            setState(() {
                              if (isCompleted) {
                                _completedActivityIds.remove(activity.activityId);
                              } else {
                                _completedActivityIds.add(activity.activityId);
                              }
                            });
                          },

                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(grey10Color)))),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(isCompleted ? Icons.check_circle : Icons.check_circle_outline_rounded, color: isCompleted ? Colors.green : Color(primaryColor), size: 40),
                                    const SizedBox(width: 10),

                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(activity.activityType, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(blackColor), decoration: isCompleted ? TextDecoration.lineThrough : null)),
                                        Text(activity.contactName ?? "Unknown", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color))),
                                        Text(activity.nextFollowUpDate != null ? DateHelper.formatToIndonesian(DateTime.parse(activity.nextFollowUpDate!)) : "No follow-up date", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color))),
                                      ],
                                    ),
                                  ],
                                ),

                                isWhatsApp ? Image.asset(icContactDetailWA) : Icon(isCall ? Icons.phone_outlined : Icons.event_note_outlined, color: Color(primaryColor), size: 30),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}