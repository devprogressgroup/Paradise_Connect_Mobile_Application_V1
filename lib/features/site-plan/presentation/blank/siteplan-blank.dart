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
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(unit),
                      const SizedBox(height: 20),
                      _buildInformasiUnit(unit),
                      const SizedBox(height: 24),
                      _buildHargaSimulasi(unit),
                      const SizedBox(height: 24),
                      _buildSpesifikasiUnit(unit),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                (unit.clusterName ?? '-').toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(blueShade900Color),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _buildStatusBadge(unit),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          unit.productName ?? '-',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
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
          child: Text(label, style: const TextStyle(fontSize: 13, color: Color(greyShade600))),
        ),
        const Text(': ', style: TextStyle(fontSize: 13, color: Color(greyShade600))),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
      _InfoItem(Icons.apartment_outlined, 'Proyek', unit.projectName),
      _InfoItem(Icons.holiday_village_outlined, 'Nama Cluster', unit.clusterName),
      _InfoItem(Icons.home_outlined, 'Nama Unit', unit.productName),
      _InfoItem(Icons.qr_code_2_outlined, 'Kode Unit', unit.blokUnit),
      _InfoItem(Icons.info_outline, 'Status', unit.isSold ? 'TERJUAL' : unit.status),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(grey9Color)),
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
                Text(label, style: const TextStyle(fontSize: 11, color: Color(greyShade600))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
      content = SizedBox(
        height: 250,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: unit.priceSchemes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => _priceSchemeCard(unit.priceSchemes[index]),
        ),
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

  Widget _priceSchemeCard(PriceScheme scheme) {
    final hasPromo = scheme.promoName != null && scheme.hargaSebelumPromo != null;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(grey9Color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scheme.name.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasPromo) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(successColor).withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                scheme.promoName!,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(successColor)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (hasPromo)
            Text(
              scheme.hargaSebelumPromo!,
              style: const TextStyle(
                fontSize: 11,
                color: Color(greyShade500),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            scheme.harga ?? '-',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(primaryColor)),
          ),
          if (scheme.bank != null) ...[
            const SizedBox(height: 2),
            Text(scheme.bank!, style: const TextStyle(fontSize: 11, color: Color(greyShade600))),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(grey9Color)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: scheme.installments.length,
              itemBuilder: (context, i) {
                final installment = scheme.installments[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(installment.name, style: const TextStyle(fontSize: 11, color: Color(greyShade600))),
                      Text(
                        installment.total,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
        const Text('Spesifikasi Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _twoColumnGrid(
          items.map((e) => _specCard(icon: e.icon, label: e.label, value: e.value!)).toList(),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(grey9Color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: const Color(primaryColor)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
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
