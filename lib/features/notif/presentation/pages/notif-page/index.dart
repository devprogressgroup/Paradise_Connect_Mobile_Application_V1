import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/features/inbox/data/arguments/inbox_detail_args.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/attandance/domain/entities/attendance_approval_entity.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_approval/attendance_approval_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_approval/attendance_approval_state.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_event.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_state.dart';
import 'package:progress_group/features/inbox/domain/entities/inbox_contact_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/core/utils/widget/attendance_alerts_widget.dart';
import 'package:progress_group/features/contact/domain/entities/activity/whatsapp_activity_entity.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_event.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_state.dart';
import 'package:progress_group/app/router.dart';
import 'package:progress_group/core/services/push_notification_service.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/notif/domain/entities/received_notif_entity.dart';
import 'package:progress_group/features/notif/presentation/state/received_notif_cubit.dart';
import 'package:progress_group/features/notif/data/models/global_notification_model.dart';
import 'package:progress_group/features/notif/presentation/state/global_notification/global_notification_cubit.dart';
import 'package:progress_group/features/notif/presentation/state/global_notification/global_notification_state.dart';
import 'package:progress_group/core/utils/widget/global_notification_dialog.dart';
import 'package:progress_group/core/services/analytics_service.dart';


enum _NotifType { activity, approval, push, globalNotif }

class _NotifItem {
  final _NotifType type;
  final dynamic data;
  final DateTime datetime;
  _NotifItem({required this.type, required this.data, required this.datetime});
}


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




class _FilterListPage<T> extends StatelessWidget {
  final String title;
  final List<({T value, String label, String? subtitle})> items;
  final T selectedValue;

  const _FilterListPage({
    required this.title,
    required this.items,
    required this.selectedValue,
  });

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
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item.value == selectedValue;
                  return Material(
                    color: Color(transparentColor),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(item.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        color: isSelected ? Color(grey10Color) : Color(whiteColor),
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(isSelected ? primaryColor : blue2Color),
                                    ),
                                  ),
                                  if (item.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(item.subtitle!, style: TextStyle(fontSize: 12, color: Color(grey5Color))),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, color: Color(primaryColor), size: 22),
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


class NotifPage extends StatefulWidget {
  const NotifPage({super.key});
  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  
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

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('notif');
    _loadAll();
  }

  void _loadAll() {
    context.read<AuthBloc>().add(FetchPermissionsEvent());
    context.read<NotifActivityBloc>().add(FetchActivitiesEvent(
      activityType: _selectedActivity.value,
      isRefresh: true,
    ));
    context.read<WhatsappActivityBloc>().add(const FetchWhatsappUnreadSummaryEvent(0));
    context.read<GlobalNotificationCubit>().load();
    if (_canManageApproval) {
      context.read<AttendanceApprovalCubit>().load(
        status: _selectedApproval.status,
        flag: _selectedApproval.flag,
      );
    }
  }

  bool get _isActivityFiltered => _selectedActivity.value != null;
  bool get _isApprovalFiltered => _selectedApproval.status != null || _selectedApproval.flag != null;
  bool get _canManageApproval {
    final s = context.read<ProfileBloc>().state;
    return s is ProfileLoaded &&
        const ['General Manager', 'Sales Manager'].contains(s.profile.positionName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, "Notifikasi", isBack: true, colorBack: Color(primaryColor), onBack: () {
              AnalyticsService.logEvent('notif_back');
              context.pop();
            }),
            const SizedBox(height: 8),

            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildActivityDropdown(),
                  if (_canManageApproval) ...[
                    const SizedBox(width: 10),
                    _buildApprovalDropdown(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 10),
            Expanded(child: _buildMixedFeed()),
          ],
        ),
      ),
    );
  }

  
  Widget _buildActivityDropdown() {
    return GestureDetector(
      onTap: () async {
        AnalyticsService.logEvent('notif_filter_activity');
        final result = await Navigator.push<_ActivityOption>(
          context,
          MaterialPageRoute(builder: (_) => _FilterListPage<_ActivityOption>(
            title: 'Activity',
            selectedValue: _selectedActivity,
            items: _activityOptions.map((o) => (value: o, label: o.label, subtitle: null as String?)).toList(),
          )),
        );
        if (result != null && mounted) {
          setState(() => _selectedActivity = result);
          context.read<NotifActivityBloc>().add(FetchActivitiesEvent(activityType: result.value, isRefresh: true));
        }
      },
      child: _filterChip(
        label: _isActivityFiltered ? _selectedActivity.label : 'Activity',
        isActive: _isActivityFiltered,
        onClear: _isActivityFiltered ? () {
          AnalyticsService.logEvent('notif_clear_filter');
          setState(() => _selectedActivity = const _ActivityOption(null, 'Activity'));
          context.read<NotifActivityBloc>().add(const FetchActivitiesEvent(isRefresh: true));
        } : null,
      ),
    );
  }

  
  Widget _buildApprovalDropdown() {
    return GestureDetector(
      onTap: () async {
        AnalyticsService.logEvent('notif_filter_approval');
        final result = await Navigator.push<_ApprovalOption>(
          context,
          MaterialPageRoute(builder: (_) => _FilterListPage<_ApprovalOption>(
            title: 'Approval',
            selectedValue: _selectedApproval,
            items: _approvalOptions.map((o) => (value: o, label: o.label, subtitle: null as String?)).toList(),
          )),
        );
        if (result != null && mounted) {
          setState(() => _selectedApproval = result);
          context.read<AttendanceApprovalCubit>().load(status: result.status, flag: result.flag);
        }
      },
      child: _filterChip(
        label: _isApprovalFiltered ? _selectedApproval.label : 'Approval',
        isActive: _isApprovalFiltered,
        onClear: _isApprovalFiltered ? () {
          AnalyticsService.logEvent('notif_clear_filter');
          setState(() => _selectedApproval = const _ApprovalOption(label: 'Approval'));
          context.read<AttendanceApprovalCubit>().load();
        } : null,
      ),
    );
  }

  
  Widget _filterChip({required String label, required bool isActive, VoidCallback? onClear}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isActive ? Color(primaryColor) : Color(whiteColor),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? Color(primaryColor) : Color(transparentColor)),
        boxShadow: [
          if (!isActive) BoxShadow(color: Color(blackColor).withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isActive ? Color(whiteColor) : Color(blackColor))),
          const SizedBox(width: 4),
          if (isActive && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded, size: 14, color: Color(whiteColor)),
            )
          else
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isActive ? Color(whiteColor) : Color(blackColor)),
        ],
      ),
    );
  }

  
  Widget _buildMixedFeed() {
    return BlocBuilder<ReceivedNotifCubit, ReceivedNotifState>(
      builder: (context, pushState) {
        return BlocBuilder<GlobalNotificationCubit, GlobalNotificationState>(
          builder: (context, globalNotifState) {
        return BlocConsumer<NotifActivityBloc, ActivityState>(
          listenWhen: (prev, curr) => curr.status == ActivityStatus.error && prev.status != ActivityStatus.error,
          listener: (context, activityState) {

          },
          builder: (context, activityState) {
            return BlocConsumer<AttendanceApprovalCubit, AttendanceApprovalState>(
              listenWhen: (prev, curr) => curr is AttendanceApprovalError && prev is! AttendanceApprovalError,
              listener: (context, approvalState) {
                if (approvalState is AttendanceApprovalError) {

                }
              },
              builder: (context, approvalState) {

                final loadingActivity = activityState.status == ActivityStatus.loading && activityState.activities.isEmpty;
                final loadingApproval = approvalState is AttendanceApprovalLoading;
                if ((_isApprovalFiltered && loadingApproval) || (_isActivityFiltered && loadingActivity) ||
                    (!_isActivityFiltered && !_isApprovalFiltered && (loadingActivity || loadingApproval))) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: buildNotifShimmer(),
                  );
                }

                final items = <_NotifItem>[];


                for (final n in pushState.items) {
                  items.add(_NotifItem(type: _NotifType.push, data: n, datetime: n.receivedAt));
                }


                if (!_isApprovalFiltered) {
                  for (final n in globalNotifState.items) {
                    items.add(_NotifItem(type: _NotifType.globalNotif, data: n, datetime: n.createdAt));
                  }
                }


                if (!_isApprovalFiltered) {
                  for (final a in activityState.activities) {
                    final dt = DateTime.tryParse(a.activityDate) ?? DateTime.tryParse(a.createdAt) ?? DateTime(2000);
                    items.add(_NotifItem(type: _NotifType.activity, data: a, datetime: dt));
                  }
                }


                if (!_isActivityFiltered && _canManageApproval && approvalState is AttendanceApprovalLoaded) {
                  for (final a in approvalState.logs) {
                    final dt = DateTime.tryParse(a.attendanceDatetime ?? '') ?? DateTime(2000);
                    items.add(_NotifItem(type: _NotifType.approval, data: a, datetime: dt));
                  }
                }

                items.sort((a, b) => b.datetime.compareTo(a.datetime));

                final showAttendanceAlerts = !_isActivityFiltered && !_isApprovalFiltered;
                final showWhatsapp = !_isApprovalFiltered &&
                    (!_isActivityFiltered || _selectedActivity.value == 'whatsapp');

                
                final List<Widget> headers = [
                  if (showAttendanceAlerts) const AttendanceAlertsWidget(),
                  if (showWhatsapp)
                    BlocBuilder<WhatsappActivityBloc, WhatsappActivityState>(
                      builder: (_, ws) {
                        if (ws.status == WhatsappUnreadSummaryStatus.loaded && ws.data.isNotEmpty) {
                          return Column(children: ws.data.map(_whatsappItem).toList());
                        }
                        return const SizedBox();
                      },
                    ),
                ];

                final int totalCount = headers.length + (items.isEmpty ? 1 : items.length);

                return RefreshIndicator(
                  onRefresh: () async => _loadAll(),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: totalCount,
                    itemBuilder: (_, i) {
                      if (i < headers.length) return headers[i];
                      if (items.isEmpty) {
                        return Padding(
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
                        );
                      }
                      final item = items[i - headers.length];
                      final Widget child;
                      if (item.type == _NotifType.activity) {
                        child = _activityItem(context, item.data as ActivityEntity);
                      } else if (item.type == _NotifType.approval) {
                        child = _approvalItem(item.data as AttendanceApprovalEntity);
                      } else if (item.type == _NotifType.globalNotif) {
                        child = _globalNotifItem(context, item.data as GlobalNotificationEntity);
                      } else {
                        child = _pushNotifItem(item.data as ReceivedNotifEntity);
                      }
                      return RepaintBoundary(child: child);
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


  
  Widget _activityItem(BuildContext context, ActivityEntity activity) {
    final isCompleted = activity.statusFollow == 1;
    final type = activity.activityType.toLowerCase();
    final isWhatsApp = type.contains('whatsapp');
    final isCall     = type.contains('call');
    final isMeeting  = type.contains('meeting');
    final isVisit    = type.contains('visit');
    final isReminder = type.contains('reminder');
    final isTask     = type.contains('task');
    final isCreatedContact = activity.activityType == 'Created contact';

    return GestureDetector(
      onTap: () async {
        AnalyticsService.logEvent('notif_open_activity_item');
        if (isCreatedContact || isCompleted) {
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
      child: _cardWrap(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(isCompleted ? Icons.check_circle : Icons.check_circle_outline_rounded,
                color: isCompleted ? Color(greenMaterialColor) : Color(primaryColor), size: 40),
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
      )),
    );
  }

  Widget _approvalItem(AttendanceApprovalEntity item) {
    final isApproved = item.isApprove == 1;
    final isRejected = item.isReject == 1;
    final statusLabel = isApproved ? 'Approve' : isRejected ? 'Reject' : 'Pending';
    final statusColor = isApproved ? Color(greenMaterialColor) : isRejected ? const Color(clockOutColor) : Color(orangeAccentColor);
    final dt = DateTime.tryParse(item.attendanceDatetime ?? '');

    return GestureDetector(
      onTap: () async {
        AnalyticsService.logEvent('notif_open_pending_approval');
        await context.pushNamed('approval');
        if (mounted) _loadAll();
      },
      child: _cardWrap(Row(children: [
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
    ])),
    );
  }

  Widget _pushNotifItem(ReceivedNotifEntity notif) {
    final type = notif.type;
    final icon = type == 'upcoming_task'         ? Icons.event_note_outlined
        : type == 'attendance'                   ? Icons.access_time_outlined
        : type == 'approval_pending' ||
          type == 'attendance_null_location'     ? Icons.how_to_reg_outlined
        : type == 'app_update'                   ? Icons.system_update_outlined
        : Icons.notifications_outlined;

    return GestureDetector(
      onTap: () {
        AnalyticsService.logEvent('notif_open_notification');
        PushNotificationService.navigateFromData(notif.data);
      },
      child: _cardWrap(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(primaryColor), size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                if (notif.body.isNotEmpty)
                  Text(notif.body, style: TextStyle(fontSize: 12, color: Color(grey2Color))),
                const SizedBox(height: 2),
                Text(DateHelper.formatDate(notif.receivedAt), style: TextStyle(fontSize: 11, color: Color(grey4Color))),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Widget _globalNotifItem(BuildContext context, GlobalNotificationEntity notif) {
    final hasImage = notif.mediaType == 'image' && (notif.mediaUrl?.isNotEmpty ?? false);
    final title = notif.title.isNotEmpty ? notif.title : 'Notifikasi';

    return GestureDetector(
      onTap: () {
        AnalyticsService.logEvent('notif_open_global_notification');
        showGlobalNotificationDialog(
          context,
          title: notif.title,
          description: notif.description ?? '',
          mediaType: notif.mediaType,
          mediaUrl: notif.mediaUrl,
          linkUrl: notif.linkUrl,
        );
      },
      child: _cardWrap(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    notif.mediaUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.notifications_outlined, color: Color(primaryColor), size: 36),
                  ),
                )
              : Icon(Icons.notifications_outlined, color: Color(primaryColor), size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                if ((notif.description ?? '').isNotEmpty)
                  Text(notif.description!, style: TextStyle(fontSize: 12, color: Color(grey2Color))),
                const SizedBox(height: 2),
                Text(DateHelper.formatDate(notif.createdAt), style: TextStyle(fontSize: 11, color: Color(grey4Color))),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Widget _whatsappItem(WhatsappUnreadSummaryEntity item) {
    return GestureDetector(
      onTap: () {
        AnalyticsService.logEvent('notif_open_whatsapp_unread');
        AppRouter.rootNavigatorKey.currentContext!.pushNamed('detailInbox', extra: InboxDetailArgs(
        data: InboxContact(
          id: item.contactId ?? 0, name: item.contactName, jid: item.jid,
          isGroup: item.jid.endsWith('@g.us'),
          initials: item.contactName.isNotEmpty ? item.contactName[0] : '?',
          sessionCode: item.sessionId, photo: item.photoProfile,
        ),
        icon: Icons.person,
      ));
      },
      child: _cardWrap(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 40, width: 5, decoration: BoxDecoration(color: Color(greenMaterialColor), borderRadius: BorderRadius.circular(16))),
        const SizedBox(width: 10),
        Expanded(child: RichText(text: TextSpan(
          style: const TextStyle(color: Color(blackColor), fontSize: 13),
          children: [
            TextSpan(text: item.contactName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: " mengirim "),
            TextSpan(text: "${item.unreadCount} pesan belum dibaca", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(greenMaterialColor))),
            const TextSpan(text: "."),
          ],
        ))),
      ])),
    );
  }

  Widget _cardWrap(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Color(whiteColor),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [BoxShadow(color: Color(greyShade500).withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))],
    ),
    child: child,
  );
}
