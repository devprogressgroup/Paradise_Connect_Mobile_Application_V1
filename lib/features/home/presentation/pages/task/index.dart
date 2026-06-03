import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/attendance_alerts_widget.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_event.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_state.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
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
            // Incomplete first, then newest (createdAt desc)
            final activities = List.of(state.activities)
              ..sort((a, b) {
                final aComplete = (a.statusFollow == 1) ? 1 : 0;
                final bComplete = (b.statusFollow == 1) ? 1 : 0;
                if (aComplete != bComplete) return aComplete.compareTo(bComplete);
                return b.createdAt.compareTo(a.createdAt);
              });

            return Stack(
              children: [
                Column(
                  children: [
                    customHeader(context, "Upcoming Task", isBack: true, colorBack: Color(primaryColor)),
                    const SizedBox(height: 16),

                    Expanded(
                      child: isLoading && activities.isEmpty
                          ? buildActivityPageShimmer()
                          : Column(
                              children: [
                                // Filter chips
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

                                // List
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 0),
                                    child: activities.isEmpty
                                        ? RefreshIndicator(
                                            onRefresh: _loadData,
                                            child: ListView(
                                              physics: const AlwaysScrollableScrollPhysics(),
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: Center(child: Text("Tidak ada task untuk hari ini")),
                                                ),
                                              ],
                                            ),
                                          )
                                        : RefreshIndicator(
                                            onRefresh: _loadData,
                                            child: ListView(
                                              physics: const AlwaysScrollableScrollPhysics(),
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              children: [
                                                const SizedBox(height: 10),
                                                const AttendanceAlertsWidget(),
                                                ...activities.map((activity) => _buildActivityItem(activity)),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),

                if (isLoading && activities.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: buildActivityPageShimmer(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityItem(activity) {
    final isCompleted = activity.statusFollow == 1;
    final type = activity.activityType.toLowerCase();
    final isWhatsApp = type.contains('whatsapp');
    final isCall = type.contains('call');
    final isMeeting = type.contains('meeting');
    final isVisit = type.contains('visit');
    final isReminder = type.contains('reminder');
    final isTask = type.contains('task');

    return GestureDetector(
      onTap: () async {
        if (isCompleted) {
          await context.pushNamed(
            'detailContact',
            extra: ContactDetailArgs(
              dataContact: ContactEntity(
                contactId: activity.contactId,
                fullName: activity.contactName,
              ),
              dataActivity: activity,
              initialTab: 0,
            ),
          );
        } else {
          int page = 6;
          String namePage = "Update Status Prospect";

          if (isCall) { page = 0; namePage = "Call"; }
          else if (isWhatsApp) { page = 1; namePage = "WhatsApp"; }
          else if (isMeeting) { page = 2; namePage = "Meeting"; }
          else if (isReminder) { page = 3; namePage = "Reminder"; }
          else if (isTask) { page = 3; namePage = "Task"; }
          else if (isVisit) { page = 4; namePage = "Visit"; }

          await context.pushNamed(
            'addContact',
            extra: ContactDetailArgs(
              page: page,
              namePage: namePage,
              dataActivity: activity,
              buttonLabel: 'Complete',
              dataContact: ContactEntity(
                contactId: activity.contactId,
                fullName: activity.contactName,
              ),
            ),
          );
        }
        if (context.mounted) _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
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
                      activity.contactName ?? '',
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
      ),
    );
  }
}
