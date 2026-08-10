import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import '../../../../core/utils/widget/custom_header.dart';
import '../../domain/entities/unit_detail.dart';

/// Contoh data unit, dipakai kalau halaman ini dibuka tanpa data (preview).
const Map<String, dynamic> _sampleUnitData = {
  "projects": "Paradise Serpong City 2",
  "cluster": "Cluster EcoArdence",
  "product": "Tahap 4.1-Ariawood 36/60",
  "blok_unit": "BA5-3",
  "status": "RBB",
  "is_sold": false,
  "spec": {
    "luas_tanah": 60,
    "luas_bangunan": 36,
    "kelebihan_tanah": null,
    "jumlah_lantai": null,
    "kamar_tidur": null,
    "kamar_mandi": null,
  },
  "price_schemes": [
    {
      "name": "Kontan Keras 1X",
      "harga": "Rp 577.000.000",
      "installments": [
        {"name": "UP", "total": "Rp 5.000.000"},
        {"name": "Angs 1", "total": "Rp 23.850.000"},
        {"name": "Angs 2", "total": "Rp 548.150.000"},
      ],
    },
    {
      "name": "Kontan Keras 3X",
      "harga": "Rp 591.000.000",
      "installments": [
        {"name": "UP", "total": "Rp 5.000.000"},
        {"name": "Angs 1", "total": "Rp 24.550.000"},
        {"name": "Angs 2", "total": "Rp 187.169.700"},
        {"name": "Angs 3", "total": "Rp 187.169.700"},
        {"name": "Angs 4", "total": "Rp 187.110.600"},
      ],
    },
    {
      "name": "KPR Super Express - Bank BCA",
      "bank": "Bank BCA",
      "promo_name": "Promo KPR Merdeka",
      "promo_percentage": 2.5,
      "harga_sebelum_promo": "Rp 584.000.000",
      "harga": "Rp 569.400.000",
      "installments": [
        {"name": "UP", "total": "Rp 5.000.000"},
        {"name": "Angs 1", "total": "Rp 24.200.000"},
        {"name": "Angs 2", "total": "Rp 146.000.000"},
        {"name": "KPR", "total": "Rp 394.200.000"},
      ],
    },
  ],
};

class SitePlanBlank extends StatefulWidget {
  final Map<String, dynamic>? data;

  const SitePlanBlank({super.key, this.data});

  @override
  State<SitePlanBlank> createState() => _SitePlanBlankState();
}

class _SitePlanBlankState extends State<SitePlanBlank> {
  final PageController _galleryController = PageController();
  int _activeImage = 0;
  bool _informasiExpanded = true;

  static const List<IconData> _galleryIcons = [
    Icons.villa_outlined,
    Icons.grid_view_outlined,
    Icons.view_in_ar_outlined,
    Icons.holiday_village_outlined,
  ];

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = UnitDetail.fromJson(widget.data ?? _sampleUnitData);

    return Scaffold(
      backgroundColor: const Color(whiteColor),
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, 'Detail Unit', isBack: true),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGallery(),
                    Padding(
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Galeri gambar (placeholder - data unit belum menyediakan URL gambar)
  // ---------------------------------------------------------------------
  Widget _buildGallery() {
    return Stack(
      children: [
        Column(
          children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: PageView.builder(
                controller: _galleryController,
                itemCount: _galleryIcons.length,
                onPageChanged: (i) => setState(() => _activeImage = i),
                itemBuilder: (context, index) => _placeholderImage(
                  icon: _galleryIcons[index],
                  size: 56,
                ),
              ),
            ),
            Container(
              height: 68,
              color: const Color(whiteColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _galleryIcons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isActive = index == _activeImage;
                  return GestureDetector(
                    onTap: () => _galleryController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? const Color(primaryColor)
                              : const Color(greyShade300),
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _placeholderImage(icon: _galleryIcons[index], size: 22),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 16,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF7A6B), Color(0xFFFF3C6E)],
              ),
            ),
            child: const Icon(Icons.share_outlined, color: Color(whiteColor), size: 18),
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage({required IconData icon, required double size}) {
    return Container(
      color: const Color(greyShade100),
      alignment: Alignment.center,
      child: Icon(icon, size: size, color: const Color(greyShade400)),
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
                  color: Color(orangeColor),
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
    final color = isSold ? const Color(redAccentColor) : const Color(successColor);
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
        color: const Color(greyShade50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(orangeColor).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: const Color(orangeColor)),
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
    if (unit.priceSchemes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Harga dan Simulasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: unit.priceSchemes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _priceSchemeCard(unit.priceSchemes[index]),
          ),
        ),
      ],
    );
  }

  Widget _priceSchemeCard(PriceScheme scheme) {
    final hasPromo = scheme.promoName != null && scheme.hargaSebelumPromo != null;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(greyShade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(greyShade200)),
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
          const Divider(height: 1, color: Color(greyShade200)),
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
        color: const Color(greyShade50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: const Color(orangeColor)),
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
