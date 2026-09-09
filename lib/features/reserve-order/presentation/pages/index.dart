import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/reserve.dart';

class ReserveOrderPage extends StatefulWidget {
  final ContactDetailArgs args;

  const ReserveOrderPage({super.key, required this.args});

  @override
  State<ReserveOrderPage> createState() => _ReserveOrderPageState();
}

class _ReserveOrderPageState extends State<ReserveOrderPage> {
  // Hasil flow Reserve yang sudah diselesaikan. Selama null, kartunya tampil polos (belum ada
  // tanda centang & rincian). Belum diambil dari server — endpoint t_reserve_order belum ada,
  // jadi isinya hilang kalau halaman ini ditutup.
  ReserveResult? _reserve;

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
            Expanded(
              child: Column(
                children: [
                  _buildItem(
                    "Reserve",
                    onTap: _openReserve,
                    // Rincian & centang baru muncul setelah flow Reserve diselesaikan.
                    details: _reserveDetails,
                    isDone: _reserve != null,
                  ),
                  _buildItem("Topup"),
                  _buildItem("RB"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Baris rincian di bawah judul: unit, lalu nilainya. Nilai dilewati selama belum ada sumber
  // datanya, jadi kartunya tidak menampilkan "Rp 0" yang menyesatkan.
  List<String> get _reserveDetails {
    final reserve = _reserve;
    if (reserve == null) return const [];

    return [
      if (reserve.unitLabel.isNotEmpty) reserve.unitLabel,
      if (reserve.amount != null) 'Rp ${NumberHelper.thousands(reserve.amount!)}',
    ];
  }

  Future<void> _openReserve() async {
    AnalyticsService.logEvent('reserve_order_open_reserve');
    final result = await context.pushNamed(
      'reserveOrderReserve',
      extra: widget.args.copyWith(namePage: "Reserve"),
    );
    if (!mounted) return;

    // Hanya diisi kalau flow-nya benar-benar diselesaikan lewat Save; kalau user menekan back,
    // hasilnya null dan status kartu dibiarkan seperti semula.
    if (result is ReserveResult) setState(() => _reserve = result);
  }

  Widget _buildItem(
    String title, {
    VoidCallback? onTap,
    List<String> details = const [],
    bool isDone = false,
  }) {
    // Topup & RB belum punya tujuan; pensilnya tetap ditampilkan seperti mockup, tapi menjelaskan
    // statusnya saat ditekan ketimbang jadi tombol mati tanpa reaksi.
    final action = onTap ?? () => showSnackbar(context, '$title is not available yet.');

    return InkWell(
      onTap: action,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Color(blackColor).withValues(alpha: 0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                  ),
                  for (final line in details)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Color(grey5Color)),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isDone) ...[
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(greenMaterialColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.check, size: 16, color: Color(whiteColor)),
                  ),
                  SizedBox(height: 10),
                ],
                InkWell(
                  onTap: action,
                  child: Icon(Icons.drive_file_rename_outline, size: 20, color: Color(primaryColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
