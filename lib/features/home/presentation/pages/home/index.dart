import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/utils/helpers/date_helper.dart';
import 'package:progress_group/features/attandance/domain/entities/attandance_entity.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_state.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_bloc.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_event.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_state.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_event.dart';
import 'package:progress_group/features/contact/presentation/state/activity/activity_state.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_event.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_state.dart';
import '../../../../../core/utils/widget/custom_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  DateTime _chartEndDate = DateTime.now();
  DateTime _chartStartDate = DateTime.now().subtract(const Duration(days: 6));
  int day = 0;
  bool isCompleted = false;

  
  @override
  void initState() {
    super.initState();
    day = _chartEndDate.difference(_chartStartDate).inDays + 1;
    _loadData();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _chartStartDate, end: _chartEndDate),
    );

    if (picked != null) {
      final calculatedDays = picked.end.difference(picked.start).inDays + 1;
      
      if (calculatedDays < 2) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Peringatan"),
              content: const Text("Minimal pilih 2 hari untuk melihat laporan."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
              ],
            ),
          );
        }
        return;
      }

      if (calculatedDays > 7) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Peringatan"),
              content: const Text("Maksimal pilih 7 hari untuk melihat laporan."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
              ],
            ),
          );
        }
        return;
      }

      setState(() {
        _chartStartDate = picked.start;
        _chartEndDate = picked.end;
        day = calculatedDays;
      });
      
      _loadData();
    }
  }

 Future<void> _loadData() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    context.read<ReportBloc>().add(GetVolumeReportEvent(
      startDate: DateFormat('yyyy-MM-dd').format(_chartStartDate),
      endDate: DateFormat('yyyy-MM-dd').format(_chartEndDate),
      groupBy: "Annual",
    ));

    context.read<ProfileBloc>().add(GetProfileEvent());

    print("todayyyyyyyyy: ${todayStr}");
    context.read<ActivityBloc>().add(
      FetchActivitiesEvent(
        followUpStartDate: todayStr,
        followUpEndDate: todayStr,
        isRefresh: true,
      ),
    );
    
    context.read<NotifActivityBloc>().add(const FetchActivitiesEvent(isRefresh: true));
    context.read<WhatsappActivityBloc>().add(const FetchWhatsappUnreadSummaryEvent(0));
    context.read<AttendanceBloc>().add(FetchAttendanceDataEvent());

    try {
      if (mounted) setState(() {});
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          BlocBuilder<NotifActivityBloc, ActivityState>(
            builder: (context, notifState) {
              return BlocBuilder<WhatsappActivityBloc, WhatsappActivityState>(
                builder: (context, whatsappState) {
                  final hasUnseenNotif = notifState.activities.any((a) => !notifState.seenActivityIds.contains(a.activityId));
                  final hasUnreadWA = whatsappState.data.isNotEmpty;
                  final showBadge = hasUnseenNotif || hasUnreadWA;

                  return customHeader(
                    context, 
                    'Dashboard',
                    iconRight: Icons.menu,
                    iconRightOnTap: () => Scaffold.of(context).openDrawer(), 
                    iconLeft: Icons.notifications_none_rounded, 
                    showBadgeLeft: showBadge,
                    iconLeftOnTap: () {
                      context.pushNamed('notif');
                    }
                  );
                },
              );
            },
          ),
          SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      String userName = "User";
                      if (state is ProfileLoaded) {
                        userName = state.profile.fullName;
                      }
                      return Text("Welcome back, $userName !", style: TextStyle(fontSize: 16, color: Color(grey2Color)));
                    },
                  ),
                    SizedBox(height: 6),
                     GestureDetector(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(grey10Color),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Image.asset(icCalendar, width: 22, height: 22),
                            const SizedBox(width: 10),
                            Text(
                              "${DateHelper.formatDate(_chartStartDate)}  - ${DateHelper.formatDate(_chartEndDate)}",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    _buildComingTask(),
                    SizedBox(height: 6),
                    Text("WhatsApp", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    _buildWhatsAppChart(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildComingTask() {
  return BlocBuilder<ActivityBloc, ActivityState>(
    builder: (context, state) {
      final activities = state.activities;

      if (state.status == ActivityStatus.loading && activities.isEmpty) {
        return buildHomeTaskShimmer();
      }

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Upcoming Task", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  context.pushNamed("taskHome");
                },
                child: Text("See All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(primaryColor))),
              ),
            ],
          ),

          SizedBox(height: 8),

          _buildAttendanceAlerts(),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),

            child: activities.isEmpty
                ? SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: Center(child: Text("No upcoming tasks for today")),
                  )
                : SizedBox(
                    height: 240,
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
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

                                        context.pushNamed(
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
                        },
                      ),
                    ),
                  ),
          ),
        ],
      );
    },
  );
}

  Widget _buildAttendanceAlerts() {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const SizedBox.shrink();

        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        AttendanceEntity? today;
        try {
          today = state.data.firstWhere((e) => e.date == todayStr);
        } catch (_) {}

        final notClockedIn = today == null || today.clockIn == null;

        bool notCheckedIn = false;
        if (today != null && today.clockIn != null && today.checkInActivity == null) {
          final clockInTime = DateTime.tryParse(today.clockIn!);
          if (clockInTime != null) {
            notCheckedIn = DateTime.now().difference(clockInTime).inMinutes >= 10;
          }
        }

        if (!notClockedIn && !notCheckedIn) return const SizedBox.shrink();

        return Column(
          children: [
            if (notClockedIn)
              _buildAttendanceAlertItem('Kamu belum Clock In hari ini', Icons.fingerprint),
            if (notCheckedIn)
              _buildAttendanceAlertItem('Kamu belum Check In hari ini', Icons.location_on_outlined),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceAlertItem(String message, IconData icon) {
    return GestureDetector(
      onTap: () => context.go('/attandance'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppChart() {
    const double maxHeight = 110.0;
    String _formatYAxisLabel(double value) {
        if (value == 0) return "0";
        if (value >= 1000000) {
          double m = value / 1000000;
          return m == m.toInt() ? "${m.toInt()}M" : "${m.toStringAsFixed(1)}M";
        }
        if (value >= 1000) {
          double k = value / 1000;
          return k == k.toInt() ? "${k.toInt()}K" : "${k.toStringAsFixed(1)}K";
        }
        return value.toInt().toString();
      }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Statistics",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.grey),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Chat Volume",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${day} Days",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          BlocBuilder<ReportBloc, ReportState>(
            builder: (context, state) {
            
              if (state is ReportInitial || state is ReportLoading) {
                return buildHomeChartShimmer();
              }
              if (state is ReportError) {
                return SizedBox(
                  height: 150,
                  child: Center(
                      child: Text(state.message, style: const TextStyle(color: Colors.red))),
                );
              }
              if (state is ReportLoaded) {
                final reportData = state.report;
                List<String> labels = [];
                List<double> values = [];

                if (reportData.categories.isEmpty || reportData.series.isEmpty) {
                  // Jika data kosong, buat label dummy berdasarkan range tanggal yang dipilih
                  for (int i = 0; i < day; i++) {
                    DateTime date = _chartStartDate.add(Duration(days: i));
                    labels.add(DateFormat('dd/MM').format(date));
                    values.add(0.0);
                  }
                } else {
                  labels = reportData.categories.take(7).toList();
                  values = List.filled(labels.length, 0.0);
                  for (var series in reportData.series) {
                    for (int i = 0; i < series.data.length && i < values.length; i++) {
                      values[i] += series.data[i].toDouble();
                    }
                  }
                }
                final double maxDataValue = values.reduce((curr, next) => curr > next ? curr : next);
                final double chartMaxValue = maxDataValue <= 0 ? 10.0 : maxDataValue * 1.2;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    const double leftLabelWidth = 35.0;
                    final double availableWidthForBars = constraints.maxWidth - leftLabelWidth;
                    final double slotWidth = availableWidthForBars / values.length;
                    final double barWidth = slotWidth * 0.4;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                            
                              ...List.generate(4, (index) {
                              
                                double val = chartMaxValue - (index * (chartMaxValue / 3.0));
                                double topPos = (index / 3.0) * maxHeight;
                                bool isLast = index == 3;

                                return Positioned(
                                  top: topPos - 6, // Center label Vertically on the line
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        child: Text(
                                          _formatYAxisLabel(val),
                                          textAlign: TextAlign.left,
                                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                        ),
                                      ),
                                      Expanded(
                                        child: isLast
                                            ? const SizedBox.shrink()
                                            : CustomPaint(
                                                size: const Size(double.infinity, 1),
                                                painter: DashedLinePainter(color: Colors.grey.withOpacity(0.3)),
                                              ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              Padding(
                                padding: const EdgeInsets.only(left: leftLabelWidth),
                                child: SizedBox(
                                  height: maxHeight,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: values.map((val) {
                                            double h = (val / chartMaxValue) * maxHeight;
                                            return _buildManualBar(h, barWidth, maxHeight);
                                          }).toList(),
                                        ),
                                      ),

                                    
                                      Positioned.fill(
                                        top: 3,
                                        child: CustomPaint(
                                          painter: TrendLinePainter(
                                            values: values,
                                            maxHeight: maxHeight,
                                            chartMaxValue: chartMaxValue,
                                            barWidth: barWidth,
                                            slotWidth: slotWidth,
                                          ),
                                        ),
                                      ),
                                      
                                      // BASELINE (GARIS DASAR) - Ditempelkan ke bawah bar
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 1,
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: leftLabelWidth),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: labels.map((label) {
                              return Container(
                                width: slotWidth,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  label,
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }


  Widget _buildManualBar(double height, double width, double chartMaxHeight) {
    double segmentHeight = chartMaxHeight / 5;

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(chartBar1Color),
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      child: OverflowBox(
        minHeight: chartMaxHeight,
        maxHeight: chartMaxHeight,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(height: segmentHeight, width: width, color: Color(chartBar5Color).withValues(alpha: 0.3)),
            Container(height: segmentHeight, width: width, color: Color(chartBar2Color).withValues(alpha: 0.4)),
            Container(height: segmentHeight, width: width, color: Color(chartBar3Color).withValues(alpha: 0.5)),
            Container(height: segmentHeight, width: width, color: Color(chartBar4Color).withValues(alpha: 0.6)),
            Container(height: segmentHeight, width: width, color: Color(chartBar5Color).withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

}


class TrendLinePainter extends CustomPainter {
  final List<double> values;
  final double maxHeight;
  final double chartMaxValue;
  final double barWidth;
  final double slotWidth;

  TrendLinePainter({
    required this.values,
    required this.maxHeight,
    required this.chartMaxValue,
    required this.barWidth,
    required this.slotWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = Color(chartLineColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Color(chartLineColor)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Color(chartLineColor).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final shadowPath = Path();

    for (int i = 0; i < values.length; i++) {
      double x = (i * slotWidth) + (slotWidth / 2);
      
    
      double y = maxHeight - (values[i] / chartMaxValue * maxHeight);

      if (i == 0) {
        path.moveTo(x, y);
        shadowPath.moveTo(x, y + 2);
      } else {
        double prevX = ((i - 1) * slotWidth) + (slotWidth / 2);
        double prevY = maxHeight - (values[i - 1] / chartMaxValue * maxHeight);

        double controlX1 = prevX + (x - prevX) / 2;
        double controlY1 = prevY;
        double controlX2 = prevX + (x - prevX) / 2;
        double controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        shadowPath.cubicTo(
          controlX1, controlY1 + 2, controlX2, controlY2 + 2, x, y + 2,
        );
      }
    }

    final fillPath = Path.from(path);
    if (values.isNotEmpty) {
      double lastX = ((values.length - 1) * slotWidth) + (slotWidth / 2);
      double firstX = (slotWidth / 2);

      fillPath.lineTo(lastX, maxHeight);
      fillPath.lineTo(firstX, maxHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(chartLineColor).withOpacity(0.5),
            Color(chartLineColor).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, maxHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(path, paint);

    for (int i = 0; i < values.length; i++) {
      double x = (i * slotWidth) + (slotWidth / 2);
      double y = maxHeight - (values[i] / chartMaxValue * maxHeight);

      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant TrendLinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.chartMaxValue != chartMaxValue;
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 4;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
























