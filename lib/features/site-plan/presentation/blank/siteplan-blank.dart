import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import '../../../../core/utils/widget/custom_header.dart';
import '../../../../core/utils/web_iframe_bridge.dart';
import '../../domain/entities/unit_detail.dart';

class SitePlanBlank extends StatefulWidget {
  final Map<String, dynamic>? data;

  const SitePlanBlank({super.key, this.data});

  @override
  State<SitePlanBlank> createState() => _SitePlanBlankState();
}

class _SitePlanBlankState extends State<SitePlanBlank> {
  bool _informasiExpanded = true;
  bool _spesifikasiExpanded = true;

  // Buat kasih tanda visual (tombol arrow) bahwa kartu skema harga bisa di-scroll horizontal —
  // tanpa ini user gampang tidak sadar ada kartu lain di sebelah kanan yang ke-cut.
  final ScrollController _priceSchemeScrollController = ScrollController();
  bool _showLeftPriceArrow = false;
  // Default true (optimis) — metrik scroll asli (position.maxScrollExtent) baru KETAHUAN
  // setelah frame pertama selesai layout (lewat _updatePriceArrowVisibility). Kalau default-nya
  // false, arrow kanan sempat tidak kelihatan sama sekali di frame pertama sebelum listener-nya
  // sempat jalan/koreksi — makanya mulai dari true, baru dikoreksi (disembunyikan) kalau
  // ternyata kontennya tidak overflow.
  bool _showRightPriceArrow = true;

  @override
  void initState() {
    super.initState();
    // Kasus PWA (docs/site-plan-mobile-pwa.md §16): redirect vendor ke "/siteplan-key" bikin
    // PWA ini boot ULANG di dalam <iframe> siteplan (bukan di outer app) — halaman ini jadi
    // nested & kecil (§16.5). Relay data ke window PARENT (outer app) lewat postMessage, supaya
    // outer app bisa render halaman ini di navigasi-nya SENDIRI (full-screen, back button
    // benar) — SAMA seperti pengalaman di mobile. Kalau BUKAN di dalam iframe (mis. dibuka lewat
    // tombol preview 👁 di outer app sendiri, atau App Link biasa), tidak melakukan apa-apa,
    // halaman ini dirender normal seperti biasa.
    final data = widget.data;
    if (data != null && isInsideIframe) {
      postUnitDetailToParent(data);
    }
    _priceSchemeScrollController.addListener(_updatePriceArrowVisibility);
    // Sekali panggil di frame pertama kadang belum cukup — metrik scroll
    // (position.maxScrollExtent) beberapa kali baru settle di frame berikutnya (nested di
    // dalam SingleChildScrollView vertikal). Susul dengan delay kecil sebagai jaring pengaman.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePriceArrowVisibility());
    Future.delayed(const Duration(milliseconds: 300), _updatePriceArrowVisibility);
  }

  @override
  void dispose() {
    _priceSchemeScrollController.dispose();
    super.dispose();
  }

  void _updatePriceArrowVisibility() {
    if (!mounted || !_priceSchemeScrollController.hasClients) return;
    final position = _priceSchemeScrollController.position;
    setState(() {
      _showLeftPriceArrow = position.pixels > 4;
      _showRightPriceArrow = position.pixels < position.maxScrollExtent - 4;
    });
  }

  void _scrollPriceSchemesBy(double delta) {
    if (!_priceSchemeScrollController.hasClients) return;
    final target = (_priceSchemeScrollController.offset + delta).clamp(
      0.0,
      _priceSchemeScrollController.position.maxScrollExtent,
    );
    _priceSchemeScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _priceScrollArrowButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(primaryColor)),
      ),
    );
  }

  // Href/URL "/siteplan-key" MENTAH yang memicu navigasi ke halaman ini — dititip di
  // widget.data['_rawHref'] oleh pemicunya (onNavigationRequest mobile / _listenSiteplanBridge
  // web / tombol preview), BUKAN bagian dari kontrak data UnitDetail. Cuma buat debug/verifikasi
  // manual, jadi SelectableText biar gampang di-copy.
  Widget _buildRawHrefDebug() {
    final rawHref = widget.data?['_rawHref'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Href tombol mentah:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(greyShade600)),
          ),
          const SizedBox(height: 4),
          SelectableText(
            rawHref ?? '(tidak ada — bukan dari trigger "Lihat Selengkapnya" asli)',
            style: const TextStyle(fontSize: 11, color: Color(greyShade600)),
          ),
        ],
      ),
    );
  }

  /// Kalau dibuka tanpa data (mis. lewat tombol preview), pakai contoh
  /// response API `/siteplan-key` (didecrypt) sebagai fallback.
  UnitDetail _resolveUnit() {
    final data = widget.data;
    if (data != null) return UnitDetail.fromJson(data);
    return UnitDetail.fromEncryptedKeyUrl(sampleEncryptedSiteplanKeyUrl) ??
        UnitDetail.fromJson(const {});
  }

  @override
  Widget build(BuildContext context) {
    final unit = _resolveUnit();

    return Scaffold(
      backgroundColor: const Color(grey11Color),
      body: SafeArea(
        child: Column(
          children: [
            customHeader(
              context,
              'Detail Unit',
              isBack: true,
              // Halaman ini bisa jadi ENTRY POINT pertama (dibuka langsung dari link share,
              // tanpa riwayat navigasi) — context.pop() bawaan customHeader bisa gagal kalau
              // stack-nya cuma 1. context.canPop() jaga-jaga itu, fallback ke halaman utama.
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
              colorBg: const Color(primaryColor),
              colorBack: const Color(whiteColor),
              colorTitle: const Color(whiteColor),
            ),
            SizedBox(height: 20),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTitleSection(unit),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRawHrefDebug(),
                      _buildInformasiUnit(unit),
                      const SizedBox(height: 24),
                      _buildSpesifikasiUnit(unit),
                       const SizedBox(height: 24),
                      _buildHargaSimulasi(unit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Judul + status
  // ---------------------------------------------------------------------
  Widget _buildTitleSection(UnitDetail unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              (unit.clusterName ?? '-').toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(blueShade900Color),
              ),
            ),
            _buildStatusBadge(unit),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          unit.productName ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _labelValueRow('Kode Unit', unit.blokUnit ?? '-'),
      ],
    );
  }

  Widget _buildStatusBadge(UnitDetail unit) {
    final isSold = unit.isSold;
    final label = isSold ? 'TERJUAL' : (unit.status ?? '-');
    final color = isSold ? const Color(redAccentColor) : const Color(primaryColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(whiteColor),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _labelValueRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(greyShade600))),
        ),
        const Text(': ', style: TextStyle(fontSize: 12, color: Color(greyShade600))),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Informasi Unit
  // ---------------------------------------------------------------------
  Widget _buildInformasiUnit(UnitDetail unit) {
    final items = <_InfoItem>[
      _InfoItem(Icons.qr_code_2_outlined, 'Kode Unit', unit.blokUnit),
      _InfoItem(Icons.home_outlined, 'Nama Unit', unit.productName),
      _InfoItem(Icons.holiday_village_outlined, 'Nama Cluster', unit.clusterName),
      _InfoItem(Icons.apartment_outlined, 'Proyek', unit.projectName),
    ].where((e) => e.value != null && e.value!.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _informasiExpanded = !_informasiExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Informasi Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(
                _informasiExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(greyShade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeOut,
          sizeCurve: Curves.easeOut,
          duration: const Duration(milliseconds: 200),
          crossFadeState: _informasiExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: _twoColumnGrid(
            items
                .map((e) => _infoCard(icon: e.icon, label: e.label, value: e.value!))
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _twoColumnGrid(List<Widget> children) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: children
          .map((c) => SizedBox(width: (MediaQuery.of(context).size.width - 16 * 2 - 10) / 2, child: c))
          .toList(),
    );
  }

  Widget _infoCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 75,
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(grey11Color),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: const Color(primaryColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(greyShade600)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 34,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Harga dan Simulasi Pembayaran
  // ---------------------------------------------------------------------
  Widget _buildHargaSimulasi(UnitDetail unit) {
    final isTerjual = (unit.status ?? '').toUpperCase() == 'SP' || unit.isSold;

    Widget content;
    if (isTerjual) {
      content = _buildPaymentEmptyState(
        icon: Icons.sell_rounded,
        iconColor: const Color(redAccentColor),
        title: 'Unit Sudah Terjual',
        subtitle: 'Simulasi harga dan pembayaran tidak tersedia karena unit ini sudah terjual.',
      );
    } else if (unit.priceSchemes.isEmpty) {
      content = _buildPaymentEmptyState(
        icon: Icons.hourglass_top_rounded,
        iconColor: const Color(greyShade500),
        title: 'Harga Belum Tersedia',
        subtitle: 'Informasi harga dan simulasi pembayaran untuk unit ini sedang kami siapkan.',
      );
    } else {
      // --- Desain baru (list vertikal + bottom sheet simulasi lengkap): dibiarkan sebagai
      // referensi, belum dihapus — lihat _buildPriceSchemeList/_priceSchemeCardV2 di bawah.
      // content = _buildPriceSchemeList(unit.priceSchemes);
      content = Stack(
        children: [
          SizedBox(
            height: 150,
            child: ListView.separated(
              controller: _priceSchemeScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: unit.priceSchemes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _priceSchemeCard(unit.priceSchemes[index]),
            ),
          ),
          if (unit.priceSchemes.length > 1) ...[
            if (_showLeftPriceArrow)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _priceScrollArrowButton(
                    icon: Icons.chevron_left,
                  
                    onTap: () => _scrollPriceSchemesBy(-190),
                  ),
                ),
              ),
            if (_showRightPriceArrow)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _priceScrollArrowButton(
                    icon: Icons.chevron_right,
                    onTap: () => _scrollPriceSchemesBy(190),
                  ),
                ),
              ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Harga dan Simulasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildPaymentEmptyState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(grey9Color)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(greyShade600), height: 1.4),
          ),
        ],
      ),
    );
  }

  // TextDecoration.lineThrough Flutter kadang render putus-putus per kata (ada gap di spasi,
  // terutama di web/CanvasKit) — gambar garis manual di atas teks pakai Stack supaya nyambung
  // utuh dalam satu garis, bukan per kata.
  Widget _strikeThroughText(String text, {required double fontSize, required Color color}) {
    return Stack(
      children: [
        Text(text, style: TextStyle(fontSize: fontSize, color: color)),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(
              widthFactor: 1,
              child: Container(height: 1, color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceSchemeCard(PriceScheme scheme) {
    final hasPromo = scheme.promoName != null && scheme.hargaSebelumPromo != null;

    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 145,
                child: Text(
                  scheme.name.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (hasPromo) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(successColor).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    // scheme.promoName!,
                    "Promo BCA",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(successColor)),
                  ),
                ),
                if (scheme.promoPercentage != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '-${scheme.promoPercentage}%',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(redAccentColor)),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (hasPromo)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Harga", style: const TextStyle(fontSize: 11, color: Color(greyShade600))),
                _strikeThroughText(
                  scheme.hargaSebelumPromo!,
                  fontSize: 11,
                  color: const Color(greyShade500),
                ),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Harga", style: const TextStyle(fontSize: 11, color: Color(greyShade600))),
              Text(
                scheme.harga ?? '-',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (scheme.installments.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Angsuran',
                  style: const TextStyle(fontSize: 11, color: Color(greyShade600)),
                ),
                Text(
                  scheme.installments.first.total,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- Desain baru: list vertikal full-width per skema harga, tombol "Lihat Simulasi
  // Lengkap" buka bottom sheet berisi breakdown SEMUA cicilan (bukan cuma yang pertama). ---
  // Widget _buildPriceSchemeList(List<PriceScheme> schemes) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       for (var i = 0; i < schemes.length; i++) ...[
  //         if (i > 0) const SizedBox(height: 12),
  //         _priceSchemeCardV2(schemes[i]),
  //       ],
  //     ],
  //   );
  // }
  //
  // Widget _priceSchemeCardV2(PriceScheme scheme) {
  //   final hasPromo = scheme.promoName != null && scheme.hargaSebelumPromo != null;
  //
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: const Color(whiteColor),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: const Color(grey9Color)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Expanded(
  //               child: Text(
  //                 scheme.name.toUpperCase(),
  //                 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
  //               ),
  //             ),
  //             if (hasPromo) ...[
  //               const SizedBox(width: 8),
  //               Container(
  //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  //                 decoration: BoxDecoration(
  //                   color: const Color(successColor).withAlpha(30),
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 child: Text(
  //                   scheme.promoName!,
  //                   style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(successColor)),
  //                 ),
  //               ),
  //             ],
  //           ],
  //         ),
  //         const SizedBox(height: 10),
  //         if (hasPromo)
  //           Row(
  //             children: [
  //               Text(
  //                 scheme.hargaSebelumPromo!,
  //                 style: const TextStyle(
  //                   fontSize: 12,
  //                   color: Color(greyShade500),
  //                   decoration: TextDecoration.lineThrough,
  //                 ),
  //               ),
  //               if (scheme.promoPercentage != null) ...[
  //                 const SizedBox(width: 6),
  //                 Text(
  //                   '-${scheme.promoPercentage}%',
  //                   style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(redAccentColor)),
  //                 ),
  //               ],
  //             ],
  //           ),
  //         Text(
  //           scheme.harga ?? '-',
  //           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(primaryColor)),
  //         ),
  //         if (scheme.bank != null) ...[
  //           const SizedBox(height: 4),
  //           Text(scheme.bank!, style: const TextStyle(fontSize: 12, color: Color(greyShade600))),
  //         ],
  //         if (scheme.installments.isNotEmpty) ...[
  //           const SizedBox(height: 12),
  //           const Divider(height: 1, color: Color(grey9Color)),
  //           const SizedBox(height: 12),
  //           SizedBox(
  //             width: double.infinity,
  //             child: OutlinedButton.icon(
  //               onPressed: () => _showInstallmentSheet(scheme),
  //               icon: const Icon(Icons.receipt_long_outlined, size: 16),
  //               label: const Text('Lihat Simulasi Lengkap'),
  //               style: OutlinedButton.styleFrom(
  //                 foregroundColor: const Color(primaryColor),
  //                 side: const BorderSide(color: Color(primaryColor)),
  //                 padding: const EdgeInsets.symmetric(vertical: 10),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }
  //
  // void _showInstallmentSheet(PriceScheme scheme) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (context) {
  //       return SafeArea(
  //         child: Padding(
  //           padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Center(
  //                 child: Container(
  //                   width: 36,
  //                   height: 4,
  //                   margin: const EdgeInsets.only(bottom: 16),
  //                   decoration: BoxDecoration(
  //                     color: const Color(grey9Color),
  //                     borderRadius: BorderRadius.circular(4),
  //                   ),
  //                 ),
  //               ),
  //               Text(scheme.name.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
  //               const SizedBox(height: 4),
  //               Text(
  //                 scheme.harga ?? '-',
  //                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(primaryColor)),
  //               ),
  //               const SizedBox(height: 16),
  //               const Text('Simulasi Cicilan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
  //               const SizedBox(height: 8),
  //               ...scheme.installments.map(
  //                 (installment) => Padding(
  //                   padding: const EdgeInsets.symmetric(vertical: 6),
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(installment.name, style: const TextStyle(fontSize: 12, color: Color(greyShade600))),
  //                       Text(installment.total, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // ---------------------------------------------------------------------
  // Spesifikasi Unit
  // ---------------------------------------------------------------------
  Widget _buildSpesifikasiUnit(UnitDetail unit) {
    final spec = unit.spec;
    final items = <_InfoItem>[
      _InfoItem(Icons.straighten_outlined, 'Luas Tanah', _fmtArea(spec.luasTanah)),
      _InfoItem(Icons.home_outlined, 'Luas Bangunan', _fmtArea(spec.luasBangunan)),
      _InfoItem(Icons.add_box_outlined, 'Kelebihan Tanah', _fmtArea(spec.kelebihanTanah)),
      _InfoItem(Icons.layers_outlined, 'Jumlah Lantai', spec.jumlahLantai?.toString()),
      _InfoItem(Icons.bed_outlined, 'Kamar Tidur', spec.kamarTidur?.toString()),
      _InfoItem(Icons.bathtub_outlined, 'Kamar Mandi', spec.kamarMandi?.toString()),
    ].where((e) => e.value != null).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _spesifikasiExpanded = !_spesifikasiExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Spesifikasi Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(
                _spesifikasiExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(greyShade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeOut,
          sizeCurve: Curves.easeOut,
          duration: const Duration(milliseconds: 200),
          crossFadeState: _spesifikasiExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: _twoColumnGrid(
            items.map((e) => _specCard(icon: e.icon, label: e.label, value: e.value!)).toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  String? _fmtArea(num? value) {
    if (value == null) return null;
    final asString = value == value.roundToDouble() ? value.toInt().toString() : value.toString();
    return '$asString m²';
  }

  Widget _specCard({required IconData icon, required String label, required String value}) {
    return Container(
      height: 75,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: const Color(primaryColor)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(greyShade600))),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String? value;

  _InfoItem(this.icon, this.label, this.value);
}
