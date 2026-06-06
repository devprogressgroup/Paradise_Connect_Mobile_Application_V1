import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/attendance_alerts_widget.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/attandance/domain/entities/attendance_approval_entity.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_approval/attendance_approval_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_approval/attendance_approval_state.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_event.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_state.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';

// ─── Filter options ───────────────────────────────────────────────────────────
class _ActivityOption {
  final String? value;
  final String label;
  const _ActivityOption(this.value, this.label);
}

class _ApprovalOption {
  final String? status;
  final int? flag;
  final String label;
  const _ApprovalOption({this.status, this.flag, required this.label});
}

// ─── Filter list page (contact-dropdown style) ────────────────────────────────
class _FilterListPage<T> extends StatelessWidget {
  final String title;
  final List<({T value, String label})> items;
  final T selectedValue;
  const _FilterListPage({required this.title, required this.items, required this.selectedValue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color(whiteColor),
                border: Border(bottom: BorderSide(width: 1, color: Color(grey9Color))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.arrow_back, color: Color(primaryColor), size: 27),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Color(grey9Color), indent: 16),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final isSelected = item.value == selectedValue;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(item.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        color: isSelected ? Color(grey10Color) : Color(whiteColor),
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(isSelected ? primaryColor : blue2Color),
                                ),
                              ),
                            ),
                            if (isSelected) Icon(Icons.check_circle, color: Color(primaryColor), size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Unified item ─────────────────────────────────────────────────────────────
enum _ItemType { activity, approval }

class _MixedItem {
  final _ItemType type;
  final dynamic data;
  final DateTime datetime;
  _MixedItem({required this.type, required this.data, required this.datetime});
}

// ═══════════════════════════════════════════════════════════════════════════════
class TaskPage extends StatefulWidget {
  const TaskPage({super.key});
  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  _ActivityOption _selectedActivity = const _ActivityOption(null, 'Activity');
  _ApprovalOption _selectedApproval = const _ApprovalOption(label: 'Approval');

  static const _activityOptions = [
    _ActivityOption(null,        'Semua'),
    _ActivityOption('whatsapp',  'WhatsApp'),
    _ActivityOption('call',      'Call'),
    _ActivityOption('visit',     'Visit'),
    _ActivityOption('reminder',  'Reminder'),
    _ActivityOption('task',      'Task'),
  ];

  static const _approvalOptions = [
    _ApprovalOption(label: 'Semua'),
    _ApprovalOption(status: 'pending', label: 'Pending'),
    _ApprovalOption(status: 'approve', label: 'Approve'),
    _ApprovalOption(status: 'reject',  label: 'Reject'),
    _ApprovalOption(flag: 0,           label: 'Clock In'),
    _ApprovalOption(flag: 1,           label: 'Clock Out'),
  ];

  bool get _isActivityFiltered => _selectedActivity.value != null;
  bool get _isApprovalFiltered => _selectedApproval.status != null || _selectedApproval.flag != null;

  bool get _canManageApproval {
    final s = context.read<ProfileBloc>().state;
    return s is ProfileLoaded &&
        const ['General Manager', 'Sales Manager'].contains(s.profile.positionName);
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    context.read<ActivityBloc>().add(FetchActivitiesEvent(
      followUpStartDate: todayStr,
      followUpEndDate: todayStr,
      activityType: _selectedActivity.value,
      isRefresh: true,
    ));
    if (_canManageApproval) {
      context.read<AttendanceApprovalCubit>().load(
        status: _isApprovalFiltered ? _selectedApproval.status : 'pending',
        flag: _selectedApproval.flag,
      );
    }
  }

  void _openActivityFilter() async {
    final result = await Navigator.push<_ActivityOption>(
      context,
      MaterialPageRoute(builder: (_) => _FilterListPage<_ActivityOption>(
        title: 'Activity',
        selectedValue: _selectedActivity,
        items: _activityOptions.map((o) => (value: o, label: o.label)).toList(),
      )),
    );
    if (result != null && mounted) {
      setState(() => _selectedActivity = result);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      context.read<ActivityBloc>().add(FetchActivitiesEvent(
        followUpStartDate: todayStr,
        followUpEndDate: todayStr,
        activityType: result.value,
        isRefresh: true,
      ));
    }
  }

  void _openApprovalFilter() async {
    final result = await Navigator.push<_ApprovalOption>(
      context,
      MaterialPageRoute(builder: (_) => _FilterListPage<_ApprovalOption>(
        title: 'Approval',
        selectedValue: _selectedApproval,
        items: _approvalOptions.map((o) => (value: o, label: o.label)).toList(),
      )),
    );
    if (result != null && mounted) {
      setState(() => _selectedApproval = result);
      context.read<AttendanceApprovalCubit>().load(status: result.status ?? 'pending', flag: result.flag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, "Upcoming Task", isBack: true, colorBack: Color(primaryColor)),
            const SizedBox(height: 8),

            // ── Filter buttons ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _filterChipButton(
                    label: _isActivityFiltered ? _selectedActivity.label : 'Activity',
                    isActive: _isActivityFiltered,
                    onTap: _openActivityFilter,
                    onClear: _isActivityFiltered ? () {
                      setState(() => _selectedActivity = const _ActivityOption(null, 'Activity'));
                      _loadAll();
                    } : null,
                  ),
                  if (_canManageApproval) ...[
                    const SizedBox(width: 10),
                    _filterChipButton(
                      label: _isApprovalFiltered ? _selectedApproval.label : 'Approval',
                      isActive: _isApprovalFiltered,
                      onTap: _openApprovalFilter,
                      onClear: _isApprovalFiltered ? () {
                        setState(() => _selectedApproval = const _ApprovalOption(label: 'Approval'));
                        context.read<AttendanceApprovalCubit>().load(status: 'pending');
                      } : null,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 4),
            Expanded(child: _buildMixedList()),
          ],
        ),
      ),
    );
  }

  Widget _filterChipButton({required String label, required bool isActive, required VoidCallback onTap, VoidCallback? onClear}) {
    return GestureDetector(
      onTap: onTap,
      child: CustomFilterButton(
        label: label,
        isSelected: isActive,
        onTap: onTap,
        onClear: onClear,
      ),
    );
  }

  Widget _buildMixedList() {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, activityState) {
        return BlocBuilder<AttendanceApprovalCubit, AttendanceApprovalState>(
          builder: (context, approvalState) {
            final loadingActivity = activityState.status == ActivityStatus.loading && activityState.activities.isEmpty;
            final loadingApproval = approvalState is AttendanceApprovalLoading;
            if ((_isApprovalFiltered && loadingApproval) ||
                (_isActivityFiltered && loadingActivity) ||
                (!_isActivityFiltered && !_isApprovalFiltered && (loadingActivity || loadingApproval))) {
              return buildActivityPageShimmer();
            }

            final items = <_MixedItem>[];

            if (!_isApprovalFiltered) {
              for (final a in activityState.activities) {
                final dt = DateTime.tryParse(a.activityDate) ?? DateTime.tryParse(a.createdAt) ?? DateTime(2000);
                items.add(_MixedItem(type: _ItemType.activity, data: a, datetime: dt));
              }
            }

            if (!_isActivityFiltered && _canManageApproval) {
              final approvals = approvalState is AttendanceApprovalLoaded ? approvalState.logs : <AttendanceApprovalEntity>[];
              for (final a in approvals) {
                // kalau tidak ada filter approval khusus, hanya tampil pending
                if (!_isApprovalFiltered && (a.isApprove == 1 || a.isReject == 1)) continue;
                final dt = DateTime.tryParse(a.attendanceDatetime ?? '') ?? DateTime(2000);
                items.add(_MixedItem(type: _ItemType.approval, data: a, datetime: dt));
              }
            }

            items.sort((a, b) => b.datetime.compareTo(a.datetime));

            return RefreshIndicator(
              onRefresh: () async => _loadAll(),
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),
                  if (!_isApprovalFiltered) const AttendanceAlertsWidget(),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Color(grey5Color)),
                            const SizedBox(height: 8),
                            Text('Tidak ada data', style: TextStyle(color: Color(grey5Color), fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ...items.map((item) => item.type == _ItemType.activity
                      ? _buildActivityItem(item.data as ActivityEntity)
                      : _buildApprovalItem(item.data as AttendanceApprovalEntity)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityItem(ActivityEntity activity) {
    final isCompleted = activity.statusFollow == 1;
    final type = activity.activityType.toLowerCase();
    final isWhatsApp = type.contains('whatsapp');
    final isCall     = type.contains('call');
    final isMeeting  = type.contains('meeting');
    final isVisit    = type.contains('visit');
    final isReminder = type.contains('reminder');
    final isTask     = type.contains('task');

    return GestureDetector(
      onTap: () async {
        if (isCompleted) {
          await context.pushNamed('detailContact', extra: ContactDetailArgs(
            dataContact: ContactEntity(contactId: activity.contactId, fullName: activity.contactName),
            dataActivity: activity, initialTab: 0,
          ));
        } else {
          int page = 6; String namePage = "Update Status Prospect";
          if (isCall)          { page = 0; namePage = "Call"; }
          else if (isWhatsApp) { page = 1; namePage = "WhatsApp"; }
          else if (isMeeting)  { page = 2; namePage = "Meeting"; }
          else if (isReminder) { page = 3; namePage = "Reminder"; }
          else if (isTask)     { page = 3; namePage = "Task"; }
          else if (isVisit)    { page = 4; namePage = "Visit"; }
          await context.pushNamed('addContact', extra: ContactDetailArgs(
            page: page, namePage: namePage, dataActivity: activity, buttonLabel: 'Complete',
            dataContact: ContactEntity(contactId: activity.contactId, fullName: activity.contactName),
          ));
        }
        if (context.mounted) _loadAll();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(isCompleted ? Icons.check_circle : Icons.check_circle_outline_rounded,
                  color: isCompleted ? Colors.green : Color(primaryColor), size: 40),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(activity.activityType, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                    color: Color(blackColor), decoration: isCompleted ? TextDecoration.lineThrough : null)),
                Text(activity.contactName ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color))),
                Text(
                  activity.nextFollowUpDate != null
                      ? DateHelper.formatToIndonesian(DateTime.parse(activity.nextFollowUpDate!))
                      : "No follow-up date",
                  style: TextStyle(fontSize: 12, color: Color(grey2Color)),
                ),
              ]),
            ]),
            isWhatsApp  ? Image.asset(icContactDetailWA, width: 30)
            : isMeeting ? Image.asset(icContactDetailMeeting, width: 30)
            : isVisit   ? Image.asset(icContactDetailVisit, width: 30)
            : Icon(isCall ? Icons.phone_outlined : Icons.event_note_outlined, color: Color(primaryColor), size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalItem(AttendanceApprovalEntity item) {
    final isApproved = item.isApprove == 1;
    final isRejected = item.isReject == 1;
    final statusLabel = isApproved ? 'Approve' : isRejected ? 'Reject' : 'Pending';
    final statusColor = isApproved ? Colors.green : isRejected ? const Color(0xFFE74C3C) : Colors.orange;
    final dt = DateTime.tryParse(item.attendanceDatetime ?? '');

    return GestureDetector(
      onTap: () async {
        await context.pushNamed('approval');
        if (mounted) _loadAll();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Row(children: [
          Icon(Icons.how_to_reg_outlined, color: Color(primaryColor), size: 36),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.fullName ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(item.flagLabel ?? '-', style: TextStyle(fontSize: 12, color: Color(grey4Color))),
            if (dt != null) Text(DateHelper.formatDate(dt), style: TextStyle(fontSize: 12, color: Color(grey4Color))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ]),
      ),
    );
  }
}
