import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';

class ReserveOrderPage extends StatefulWidget {
  final ContactDetailArgs args;

  const ReserveOrderPage({super.key, required this.args});

  @override
  State<ReserveOrderPage> createState() => _ReserveOrderPageState();
}

class _ReserveOrderPageState extends State<ReserveOrderPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(grey11Color),
      body: SafeArea(
        child: Column(
          children: [
            customHeader(
              context,
              widget.args.namePage ?? "Reserve Order",
              isBack: true,
              colorBack: Color(primaryColor),
              onBack: () {
                AnalyticsService.logEvent('reserve_order_back');
                context.pop();
              },
            ),
            SizedBox(height: 10),
            Expanded(child: Column(
              children: [
                _buildItem("Reserve", onTap: _openReserve),
                _buildItem("Topup"),
                _buildItem("RB"),
              ],
            )),
          ],
        ),
      ),
    );
  }

  void _openReserve() {
    AnalyticsService.logEvent('reserve_order_open_reserve');
    context.pushNamed('reserveOrderReserve', extra: widget.args.copyWith(namePage: "Reserve"));
  }

  Widget _buildItem(String title, {VoidCallback? onTap}){
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Color(blackColor).withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(child: Text(title)),
            if (onTap != null) Icon(Icons.chevron_right, size: 20, color: Color(grey5Color)),
          ],
        ),
      ),
    );
  }
}
