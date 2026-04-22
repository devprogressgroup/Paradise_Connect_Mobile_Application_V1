import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/features/home/data/datasource/chart_service.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_bloc.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_event.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_state.dart';

import '../../../../core/utils/widget/custom_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChartService _chartService = ChartService();

  // DateTime _chartStartDate = DateTime(2026, 1, 1);
  // DateTime _chartEndDate = DateTime(2026, 1, 7);
  DateTime _chartEndDate = DateTime.now();
  DateTime _chartStartDate = DateTime.now().subtract(const Duration(days: 6));
  int day = 0;

  
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
      // Menghitung jumlah hari yang dipilih
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

      // 2. Simpan nilai calculatedDays ke variabel day di dalam setState
      setState(() {
        _chartStartDate = picked.start;
        _chartEndDate = picked.end;
        day = calculatedDays; // <--- Masukkan ke sini
      });
      
      _loadData();
    }
  }

  Future<void> _loadData() async {
    
    if (mounted) {
      context.read<ReportBloc>().add(
        GetVolumeReportEvent(
          startDate: DateFormat('yyyy-MM-dd').format(_chartStartDate),
          endDate: DateFormat('yyyy-MM-dd').format(_chartEndDate),
          groupBy: "Annual",
        ),
      );
    }

    try {
      await _chartService.fetchChartData();
      setState(() {
      });
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          customHeader(context, 'Dashboard',iconRight: Icons.menu,iconRightOnTap: () => Scaffold.of(context).openDrawer(), iconLeft: Icons.notifications_none_rounded, iconLeftOnTap: () {
            context.pushNamed('notif');
          }),
          SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back, User", style: TextStyle(fontSize: 16, color: Color(grey2Color))),
                  SizedBox(height: 6),
                   GestureDetector(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(grey1Color),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Image.asset(icCalendar, width: 22, height: 22),
                          const SizedBox(width: 10),
                          Text(
                            "${DateFormat('MMM dd, yyyy').format(_chartStartDate)} - ${DateFormat('MMM dd, yyyy').format(_chartEndDate)}",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text("Funnel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Row(children: [_buildCard(), _buildCard()]),
                  Row(children: [_buildCard(), _buildCard()]),
                  Row(children: [_buildCard(), _buildCard()]),
                  SizedBox(height: 6),
                  Text("WhatsApp", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  _buildchart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6,right: 3,left: 3),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Color(whiteColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text("Leads :", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(grey2Color))),
                  Text("250", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(blackColor))),
                  Row(
                    children: [
                      Text("(Growth ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(blackColor))),
                      Text("10%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(greenPercentColor))),
                      Text(")", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(blackColor))),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("→ 40 %", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(blackColor))),
                      Text("Conv.", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(blackColor))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Leads", style: TextStyle(fontSize: 8,fontWeight: FontWeight.bold,color: Color(grey3Color))),
                      Row(
                        children: [
                          Container(
                            height: 6,
                            width: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(bluePeriodColor),
                            ),
                          ),
                          Text("10", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(blackColor))),
                          SizedBox(width: 5),
                          Text("-", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(blackColor))),
                          SizedBox(width: 5),
                          Container(
                            height: 6,
                            width: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(redPeriodColor),
                            ),
                          ),
                          Text("10", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(blackColor))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildchart() {
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
                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                );
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
                                        top: 10,
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
























