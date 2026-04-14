import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/features/home/data/models/chart_model.dart';
import 'package:progress_group/features/home/data/datasource/chart_service.dart';

import '../../../../core/utils/widget/custom_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChartService _chartService = ChartService();
  bool _isLoading = true;
  String _selectedPeriod = 'Annual';
  final List<String> _periods = ['Annual', 'Monthly', 'Weekly'];

  List<ChartModel> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _chartService.fetchChartData();
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(grey1Color),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Image.asset(icCalendar, width: 22, height: 22),
                        SizedBox(width: 10),
                        Text("Nov 16, 2020 - Dec 16, 20206",style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold, color: Color(grey2Color))),
                      ],
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
                  _buildChart(),
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

  Widget _buildChart() {
    const double maxHeight = 110.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2),spreadRadius: 2,blurRadius: 5,offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Statistics",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(grey3Color))),
                  const Text(
                    "Chat Volume",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Color(backgroundColor), borderRadius: BorderRadius.circular(20)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(grey9Color)),
                    style: TextStyle(color: Color(grey9Color), fontSize: 12, fontWeight: FontWeight.bold),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPeriod = newValue;
                        });
                      }
                    },
                    items: _periods.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              if (_isLoading) {
                return const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (_chartData.isEmpty) {
                return const SizedBox(
                  height: 250,
                  child: Center(child: Text("No data available")),
                );
              }

              final List<double> values = _chartData.map((m) => m.value).toList();
              final List<String> labels = _chartData.map((m) => m.label).toList();

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
                          double val = 3.0 - index;
                          double topPos = (index / 3.0) * maxHeight;
                          bool isLast = index == 3;

                          return Positioned(
                            top: topPos,
                            left: 0,
                            right: 0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Transform.translate(
                                    offset: const Offset(0, -6),
                                    child: Text(
                                      val == 4.0 ? "" : "${val.toInt()}M",
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600])
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: isLast ? Container(height: 1, color: Colors.grey.withOpacity(0.5))
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
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: values.map((val) {
                                    double h = (val / 3.0) * maxHeight;
                                    return _buildManualBar(h, barWidth, maxHeight);
                                  }).toList(),
                                ),

                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: TrendLinePainter(
                                      values: values,
                                      maxHeight: maxHeight,
                                      barWidth: barWidth,
                                      slotWidth: slotWidth,
                                    ),
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
                      children: labels.map((year) {
                        return Container(
                          width: slotWidth,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            year,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
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
      decoration: BoxDecoration(color: Color(chartBarBgColor), borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
      child: OverflowBox(
        minHeight: chartMaxHeight,
        maxHeight: chartMaxHeight,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(height: segmentHeight, width: width, color: Color(chartBar1Color)),
            Container(height: segmentHeight, width: width, color: Color(chartBar2Color)),
            Container(height: segmentHeight, width: width, color: Color(chartBar3Color)),
            Container(height: segmentHeight, width: width, color: Color(chartBar4Color)),
            Container(height: segmentHeight, width: width, color: Color(chartBar5Color)),
          ],
        ),
      ),
    );
  }
}

class TrendLinePainter extends CustomPainter {
  final List<double> values;
  final double maxHeight;
  final double barWidth;
  final double slotWidth;

  TrendLinePainter({
    required this.values,
    required this.maxHeight,
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
      double y = maxHeight - (values[i] / 3.0 * maxHeight);

      if (i == 0) {
        path.moveTo(x, y);
        shadowPath.moveTo(x, y + 2);
      } else {
        double prevX = ((i - 1) * slotWidth) + (slotWidth / 2);
        double prevY = maxHeight - (values[i - 1] / 3.0 * maxHeight);

        double controlX1 = prevX + (x - prevX) / 2;
        double controlY1 = prevY;
        double controlX2 = prevX + (x - prevX) / 2;
        double controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        shadowPath.cubicTo(
          controlX1,
          controlY1 + 2,
          controlX2,
          controlY2 + 2,
          x,
          y + 2,
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
            Color(chartAreaColor).withOpacity(0.5),
            Color(chartAreaColor).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, maxHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(path, paint);

    for (int i = 0; i < values.length; i++) {
      double x = (i * slotWidth) + (slotWidth / 2);
      double y = maxHeight - (values[i] / 3.0 * maxHeight);

      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
