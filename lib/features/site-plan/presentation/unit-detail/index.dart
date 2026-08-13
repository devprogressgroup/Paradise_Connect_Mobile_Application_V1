import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import '../../../../core/utils/widget/custom_header.dart';
import '../../domain/entities/unit_detail.dart';
import '../state/siteplan_bloc.dart';

/// Detail satu unit (informasi, spesifikasi, harga & simulasi pembayaran) — beda dari
/// [SitePlanBlank] (yang menampilkan payload unit hasil decrypt dari WebView siteplan, sudah
/// "beku" sejak user klik pin), halaman ini SELALU fetch data TERBARU dari API
/// `/property-pricing` (harga & promo bisa berubah setelah link/preview lama dibuka).
class UnitDetailPage extends StatefulWidget {
  final int siteplanId;
  final int companyId;
  final int productId;
  final int propertyId;
  // Kalau diisi (mis. tombol preview 💰 sebelum endpoint /property-pricing bisa diakses dari
  // device tes), halaman ini render data ini LANGSUNG — TIDAK fetch ke API sama sekali,
  // siteplanId/companyId/dst di atas jadi tidak dipakai.
  final Map<String, dynamic>? previewData;

  const UnitDetailPage({
    super.key,
    this.siteplanId = 0,
    this.companyId = 0,
    this.productId = 0,
    this.propertyId = 0,
    this.previewData,
  });

  @override
  State<UnitDetailPage> createState() => _UnitDetailPageState();
}

enum _LoadStatus { loading, loaded, error }

class _UnitDetailPageState extends State<UnitDetailPage> {
  _LoadStatus _status = _LoadStatus.loading;
  UnitDetail? _unit;
  String? _errorMessage;

  bool _informasiExpanded = true;
  bool _spesifikasiExpanded = true;
  bool _hargaExpanded = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.previewData != null) {
      setState(() {
        _unit = UnitDetail.fromJson(widget.previewData!);
        _status = _LoadStatus.loaded;
      });
      return;
    }

    setState(() => _status = _LoadStatus.loading);
    try {
      final unit = await context.read<SiteplanBloc>().repository.getUnitDetail(
            siteplanId: widget.siteplanId,
            companyId: widget.companyId,
            productId: widget.productId,
            propertyId: widget.propertyId,
          );
      if (!mounted) return;
      setState(() {
        _unit = unit;
        _status = _LoadStatus.loaded;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _status = _LoadStatus.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(grey11Color),
      body: SafeArea(
        child: Column(
          children: [
            customHeader(
              context,
              'Unit Detail',
              isBack: true,
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
              colorBg: const Color(primaryColor),
              colorBack: const Color(whiteColor),
              colorTitle: const Color(whiteColor),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(redAccentColor), size: 40),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Gagal memuat data harga unit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(redAccentColor)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
              ],
            ),
          ),
        );
      case _LoadStatus.loaded:
        final unit = _unit!;
        // Judul unit dipisah dari SingleChildScrollView di bawah supaya tetap nempel di atas
        // (tidak ikut ke-scroll) — cuma "Informasi Unit"/"Spesifikasi Unit"/"Harga & Simulasi"
        // yang scroll.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildTitleSection(unit),
            ),
            // Text("Hasil diklik titik site plan: "),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInformasiUnit(unit),
                    _buildSpesifikasiUnit(unit),
                    _buildHargaSimulasi(unit),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  // ---------------------------------------------------------------------
  // Judul + status (versi ringkas — halaman ini fokus ke harga saja)
  // ---------------------------------------------------------------------
  Widget _buildTitleSection(UnitDetail unit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  (unit.clusterName ?? '-').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(blueShade900Color),
                  ),
                ),
              ),
              _buildStatusBadge(unit),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            unit.productName ?? '-',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UnitDetail unit) {
    final isSold = unit.isSold;
    final label = isSold ? 'TERJUAL' : (unit.status ?? '-');
    final color = isSold ? const Color(redAccentColor) : const Color(primaryColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: const TextStyle(color: Color(whiteColor), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Informasi Unit
  // ---------------------------------------------------------------------
  Widget _buildInformasiUnit(UnitDetail unit) {
    final items = <_InfoItem>[
      _InfoItem(Icons.qr_code_2_outlined, 'No Blok', unit.blokUnit),
      _InfoItem(Icons.home_outlined, 'Nama Unit', unit.productName),
      _InfoItem(Icons.holiday_village_outlined, 'Nama Cluster', unit.clusterName),
      _InfoItem(Icons.apartment_outlined, 'Proyek', unit.projectName),
    ].where((e) => e.value != null && e.value!.isNotEmpty).toList();

    if (items.isEmpty) return const SizedBox.shrink();

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
            items.map((e) => _infoCard(icon: e.icon, label: e.label, value: e.value!)).toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 14),
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

  // ---------------------------------------------------------------------
  // Harga dan Simulasi Pembayaran — satu kartu per skema, ditumpuk vertikal (ikut scroll
  // halaman, BUKAN carousel horizontal lagi). Tiap kartu: judul skema + harga dasar, lalu
  // per bank promo (kalau ada) tampil sebagai sub-section sendiri (nama bank, bunga, angsuran).
  // ---------------------------------------------------------------------
  Widget _buildHargaSimulasi(UnitDetail unit) {
    final isTerjual = (unit.status ?? '').toUpperCase() == 'SP' || unit.isSold;

    if (isTerjual) {
      return _buildEmptyState(
        icon: Icons.sell_rounded,
        iconColor: const Color(redAccentColor),
        title: 'Unit Sudah Terjual',
        subtitle: 'Simulasi harga dan pembayaran tidak tersedia karena unit ini sudah terjual.',
      );
    }
    if (unit.priceSchemes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.hourglass_top_rounded,
        iconColor: const Color(greyShade500),
        title: 'Harga Belum Tersedia',
        subtitle: 'Informasi harga dan simulasi pembayaran untuk unit ini sedang kami siapkan.',
      );
    }

    // Skema yang ada promo bank-nya selalu ditaruh duluan — itu yang paling menarik buat
    // ditawarkan, jangan sampai ketutup/harus di-scroll dulu buat ketemu.
    final hasPromo = (PriceScheme s) =>
        s.promo.isNotEmpty || (s.promoName != null && s.hargaSebelumPromo != null);
    final orderedSchemes = [
      ...unit.priceSchemes.where(hasPromo),
      ...unit.priceSchemes.where((s) => !hasPromo(s)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _hargaExpanded = !_hargaExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harga dan Simulasi Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Icon(
                _hargaExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
          crossFadeState: _hargaExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < orderedSchemes.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _priceSchemeCard(orderedSchemes[i]),
              ],
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
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
            decoration: BoxDecoration(color: iconColor.withAlpha(26), shape: BoxShape.circle),
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
    // Bunga TERKECIL di antara varian bank skema ini yang paling menguntungkan buat user —
    // cuma itu yang dikasih badge hijau (successColor), sisanya badge netral (abu-abu).
    final percentages = scheme.promo
        .map((p) => p.promoPercentage)
        .whereType<num>()
        .toList();
    final lowestPromoPercentage = percentages.isEmpty ? null : percentages.reduce((a, b) => a < b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  scheme.name.toUpperCase(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                scheme.harga ?? '-',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(grey9Color)),
          const SizedBox(height: 10),
          ..._installmentRows(scheme.installments),
          for (final bankPromo in scheme.promo) ...[
            const SizedBox(height: 14),
            Text(
              (bankPromo.bank ?? bankPromo.name).toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (bankPromo.promoPercentage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bunga', style: TextStyle(fontSize: 12, color: Color(greyShade600))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: (bankPromo.promoPercentage == lowestPromoPercentage
                                ? const Color(successColor)
                                : const Color(greyShade500))
                            .withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${bankPromo.promoPercentage}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: bankPromo.promoPercentage == lowestPromoPercentage
                              ? const Color(successColor)
                              : const Color(greyShade500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ..._installmentRows(bankPromo.installments),
          ],
        ],
      ),
    );
  }

  // Label posisional ("Angsuran 1x", "Angsuran 2x", dst) dipakai alih-alih nama installment
  // mentah — nama installment dari API sering cuma duplikat nama skema/bank di atasnya
  // (mis. "KPR - Bank BCA"), keliatan ngulang kalau ditampilkan lagi apa adanya di sini.
  List<Widget> _installmentRows(List<Installment> installments) {
    return [
      for (var i = 0; i < installments.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Angsuran ${i + 1}x', style: const TextStyle(fontSize: 12, color: Color(greyShade600))),
              Text(installments[i].total, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
    ];
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String? value;

  _InfoItem(this.icon, this.label, this.value);
}
