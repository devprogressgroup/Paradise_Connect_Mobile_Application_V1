import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/presentation/state/unit_picker/unit_picker_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/unit_picker/unit_picker_state.dart';

/// Picker unit multi-select (Model A). Buka via Navigator.push, kembalikan List<SelectedUnit> saat konfirmasi.
class UnitPickerScreen extends StatefulWidget {
  final int townshipId;
  final String townshipName;
  final List<SelectedUnit> initial;

  const UnitPickerScreen({
    super.key,
    required this.townshipId,
    required this.townshipName,
    this.initial = const [],
  });

  @override
  State<UnitPickerScreen> createState() => _UnitPickerScreenState();
}

class _UnitPickerScreenState extends State<UnitPickerScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const _bluePill = Color(0xFFE6F1FB);
  static const _blueText = Color(0xFF0C447C);
  static const _selectedBg = Color(0xFFE8F2FE);
  static const _amber = Color(0xFF854F0B);

  @override
  void initState() {
    super.initState();
    context.read<UnitPickerCubit>().init(
          widget.townshipId,
          townshipName: widget.townshipName,
          initial: widget.initial,
        );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<UnitPickerCubit>().setSearch(q.trim());
    });
  }

  // Kunci seleksi — HARUS selaras dengan SelectedUnit.key.
  String _key(int clusterId, int productId, int propertyId, bool waiting) =>
      '$clusterId|$productId|$propertyId|${waiting ? 1 : 0}';

  Widget _checkbox(bool checked) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: checked ? Color(primaryColor) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: checked ? Color(primaryColor) : Color(grey5Color), width: 1.5),
        ),
        child: checked ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
      );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UnitPickerCubit>();
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: SafeArea(
        child: BlocBuilder<UnitPickerCubit, UnitPickerState>(
          builder: (context, state) {
            return Column(
              children: [
                _header(state),
                _townshipPill(),
                _searchBar(),
                const Divider(height: 1),
                Expanded(child: _body(context, cubit, state)),
                _bottomBar(context, cubit, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(UnitPickerState state) {
    final n = state.selected.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(blue2Color)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text('Pilih unit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (n > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(color: _bluePill, borderRadius: BorderRadius.circular(999)),
              child: Text('$n dipilih', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _blueText)),
            ),
        ],
      ),
    );
  }

  Widget _townshipPill() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _bluePill, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city, size: 15, color: _blueText),
                const SizedBox(width: 6),
                Text(widget.townshipName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _blueText)),
              ],
            ),
          ),
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Cari cluster, tipe, atau kavling…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      context.read<UnitPickerCubit>().setSearch('');
                      setState(() {});
                    },
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

  Widget _body(BuildContext context, UnitPickerCubit cubit, UnitPickerState state) {
    if (state.status == UnitPickerStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == UnitPickerStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 8),
            Text(state.errorMessage ?? 'Gagal memuat unit', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: cubit.loadTree, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (state.clusters.isEmpty) {
      return const Center(child: Text('Tidak ada unit tersedia', style: TextStyle(color: Colors.grey)));
    }

    return ListView(
      children: [
        for (final cluster in state.clusters) ..._clusterTile(cubit, state, cluster),
      ],
    );
  }

  List<Widget> _clusterTile(UnitPickerCubit cubit, UnitPickerState state, UnitCluster cluster) {
    final expanded = state.expandedClusters.contains(cluster.projectId);
    return [
      InkWell(
        onTap: () => cubit.toggleCluster(cluster.projectId),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x14000000)))),
          child: Row(
            children: [
              Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 20, color: expanded ? Color(primaryColor) : Color(grey5Color)),
              const SizedBox(width: 8),
              Expanded(child: Text(cluster.projectName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
      ),
      if (expanded)
        for (final product in cluster.products) ..._productTile(cubit, state, cluster, product),
    ];
  }

  List<Widget> _productTile(UnitPickerCubit cubit, UnitPickerState state, UnitCluster cluster, UnitProduct product) {
    // Key produk KOMPOSIT (company|product) — cegah bentrok product_id sama beda company dlm 1 township.
    final pkey = UnitPickerCubit.productKey(product);
    final expanded = state.expandedProducts.contains(pkey);
    final loadingLots = state.loadingProductIds.contains(pkey);
    final lots = state.lotsByProduct[pkey] ?? const [];
    return [
      InkWell(
        onTap: () => cubit.toggleProduct(product),
        child: Container(
          color: const Color(0xFFF7FAFE),
          padding: const EdgeInsets.fromLTRB(36, 11, 14, 11),
          child: Row(
            children: [
              Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 18, color: expanded ? Color(primaryColor) : Color(grey5Color)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.displayName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    if (product.spec != null)
                      Text(product.spec!, style: TextStyle(fontSize: 11.5, color: Color(grey5Color))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (expanded) ...[
        _selectRow(
          label: 'Belum menentukan kavling',
          italic: true,
          color: Color(grey5Color),
          checked: cubit.isSelected(_key(cluster.projectId, product.productId, 0, false)),
          onTap: () => cubit.toggleUndecided(cluster, product),
        ),
        _selectRow(
          label: 'Waiting list',
          italic: true,
          color: _amber,
          checked: cubit.isSelected(_key(cluster.projectId, product.productId, 0, true)),
          onTap: () => cubit.toggleWaiting(cluster, product),
        ),
        if (loadingLots)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
        else
          for (final lot in lots)
            _selectRow(
              label: lot.propertyName,
              checked: cubit.isSelected(_key(cluster.projectId, product.productId, lot.propertyId, false)),
              hook: lot.isTipeHoek,
              onTap: () => cubit.toggleLot(cluster, product, lot),
            ),
      ],
    ];
  }

  Widget _selectRow({
    required String label,
    required bool checked,
    required VoidCallback onTap,
    bool italic = false,
    Color? color,
    bool hook = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(56, 11, 14, 11),
        decoration: BoxDecoration(
          color: checked ? _selectedBg : null,
          border: const Border(top: BorderSide(color: Color(0x10000000))),
        ),
        child: Row(
          children: [
            _checkbox(checked),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  color: color ?? Color(blue2Color),
                  fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (hook)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: _bluePill, borderRadius: BorderRadius.circular(4)),
                child: const Text('Hook', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _blueText)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, UnitPickerCubit cubit, UnitPickerState state) {
    final selected = state.selected.values.toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x14000000)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final u in selected)
                    InputChip(
                      label: Text(u.label, style: const TextStyle(fontSize: 11.5, color: _blueText)),
                      backgroundColor: _bluePill,
                      onDeleted: () => cubit.removeKey(u.key),
                      deleteIcon: const Icon(Icons.close, size: 14, color: _blueText),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // Boleh konfirmasi KOSONG → kembalikan [] = "Belum menentukan unit" (membersihkan pilihan).
              onPressed: () => Navigator.of(context).pop(selected),
              icon: Icon(selected.isEmpty ? Icons.remove_circle_outline : Icons.check, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: selected.isEmpty ? Color(grey5Color) : Color(blue3Color),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              label: Text(selected.isEmpty ? 'Belum menentukan unit' : 'Konfirmasi ${selected.length} unit dipilih',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
