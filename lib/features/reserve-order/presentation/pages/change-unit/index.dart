import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';
import 'package:progress_group/features/contact/presentation/state/unit_picker/unit_picker_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/unit_picker/unit_picker_state.dart';
import 'package:progress_group/features/reserve-order/domain/entities/change_reserve_order_unit_params.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_detail/reserve_order_detail_cubit.dart';

/// "Ganti Unit" — opsi perbaikan reserve order Ditolak, selama order belum di-approve Kasir
/// (`can_change_unit`). Tampilan SAMA dgn step "Pilih Unit" wizard Create ([create/index.dart]):
/// field Project (di sini read-only — server menolak project lain), tab "Unit Saat Ini" / "Pilih Unit
/// Pengganti" (pengganti "Unit dari Contact" / "Pilih Unit Lain"), pohon cluster → tipe → kavling
/// ([UnitPickerCubit] — instance sendiri, supaya state wizard tidak ikut berubah), tapi pilih SATU unit.
/// Simpan → `POST /reserve-order/unit/{id}`: kavling divalidasi server sama dgn Ganti Unit Kasir web,
/// order Ditolak langsung diajukan ulang.
class ChangeUnitReserveOrderPage extends StatelessWidget {
  final int reserveOrderId;
  final int townshipId;
  final String? townshipName;
  final String currentUnitName;

  /// Cluster · tipe unit sekarang (tab "Unit Saat Ini").
  final String currentUnitContext;

  const ChangeUnitReserveOrderPage({
    super.key,
    required this.reserveOrderId,
    required this.townshipId,
    this.townshipName,
    required this.currentUnitName,
    this.currentUnitContext = '',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final shared = context.read<UnitPickerCubit>();
        return UnitPickerCubit(shared.getHierarchy, shared.getLots)
          ..init(townshipId, townshipName: townshipName);
      },
      child: _ChangeUnitView(page: this),
    );
  }
}

/// Unit tujuan terpilih — kavling ([propertyId]) atau tanpa kavling ([unitMode]).
class _UnitChoice {
  final String key;
  final String label;
  final String context;
  final int? propertyId;
  final String? unitMode;
  final int productId;
  final int townshipId;
  final int companyId;

  const _UnitChoice({
    required this.key,
    required this.label,
    required this.context,
    this.propertyId,
    this.unitMode,
    required this.productId,
    required this.townshipId,
    required this.companyId,
  });
}

class _ChangeUnitView extends StatefulWidget {
  final ChangeUnitReserveOrderPage page;

  const _ChangeUnitView({required this.page});

  @override
  State<_ChangeUnitView> createState() => _ChangeUnitViewState();
}

class _ChangeUnitViewState extends State<_ChangeUnitView> {
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _tab = 'replacement';
  _UnitChoice? _selected;
  bool _submitting = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      context.read<UnitPickerCubit>().setSearch(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.page.townshipName;
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: const Color(whiteColor),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tampilan sama dgn field "Pilih Project" wizard Create, tapi read-only.
                      _pickerFieldRow(
                        label: 'Pilih Project',
                        value: (project ?? '').isEmpty ? '-' : project,
                        required: true,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _unitTabButton(
                              'Unit Saat Ini',
                              _tab == 'current',
                              () => setState(() => _tab = 'current'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _unitTabButton(
                              'Pilih Unit Pengganti',
                              _tab == 'replacement',
                              () => setState(() => _tab = 'replacement'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_tab == 'current')
                        _currentUnit()
                      else ...[
                        TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: const Color(grey11Color),
                            hintText: '🔍 Cari cluster, tipe, atau kavling…',
                            hintStyle: const TextStyle(
                              color: Color(grey5Color),
                              fontSize: 12.5,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: _fieldBorder(),
                            enabledBorder: _fieldBorder(),
                            focusedBorder: _fieldBorder(focused: true),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _unitsTree(),
                      ],
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(
              Icons.arrow_back,
              color: Color(primaryColor),
              size: 27,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Ganti Unit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Gaya di bawah ini SAMA dgn step "Pilih Unit" wizard Create (create/index.dart). =====

  Widget _pickerFieldRow({
    required String label,
    required String? value,
    bool required = false,
  }) {
    const labelColor = Color(grey2Color);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      constraints: const BoxConstraints(minHeight: 50),
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        border: Border(bottom: BorderSide(width: 1, color: Color(grey9Color))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                    children: [
                      TextSpan(text: label),
                      if (required)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: Color(redColor),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  value ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(blackColor),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 28, color: Color(grey4Color)),
        ],
      ),
    );
  }

  InputBorder _fieldBorder({bool focused = false}) => UnderlineInputBorder(
    borderSide: BorderSide(
      color: Color(focused ? primaryColor : grey7Color),
    ),
  );

  Widget _unitTabButton(String label, bool selected, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(selected ? primaryColor : grey11Color),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(selected ? whiteColor : grey1Color),
            ),
          ),
        ),
      );

  Widget _infoNotice(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(roNoticeInfoBgColor),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(roNoticeInfoTextColor),
        height: 1.4,
      ),
    ),
  );

  Widget _checkbox(bool checked) => Container(
    width: 19,
    height: 19,
    decoration: BoxDecoration(
      color: checked ? const Color(primaryColor) : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: Color(checked ? primaryColor : grey7Color),
        width: 1.5,
      ),
    ),
    child: checked
        ? const Icon(Icons.check, size: 13, color: Color(whiteColor))
        : null,
  );

  /// Tab "Unit Saat Ini" — kartu gaya baris "Unit dari Contact" wizard Create, tanpa checkbox.
  Widget _currentUnit() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(whiteColor),
            border: Border.all(color: const Color(grey10Color), width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.page.currentUnitName,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.page.currentUnitContext.isNotEmpty)
                Text(
                  widget.page.currentUnitContext,
                  style: const TextStyle(fontSize: 10, color: Color(grey4Color)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _infoNotice(
          'Pilih unit baru di tab "Pilih Unit Pengganti" — hanya di project yang sama.',
        ),
      ],
    );
  }

  Widget _unitsTree() {
    return BlocBuilder<UnitPickerCubit, UnitPickerState>(
      builder: (context, state) {
        if (state.status == UnitPickerStatus.loading ||
            state.status == UnitPickerStatus.initial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == UnitPickerStatus.error) {
          return _infoNotice(state.errorMessage ?? 'Gagal memuat unit.');
        }
        if (state.clusters.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Tidak ada cluster/tipe/kavling yang cocok.',
              style: TextStyle(fontSize: 12, color: Color(grey4Color)),
            ),
          );
        }
        final cubit = context.read<UnitPickerCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final cluster in state.clusters)
              ..._clusterTiles(cubit, state, cluster),
          ],
        );
      },
    );
  }

  List<Widget> _clusterTiles(
    UnitPickerCubit cubit,
    UnitPickerState state,
    UnitCluster cluster,
  ) {
    final expanded = state.expandedClusters.contains(cluster.projectId);
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: InkWell(
          onTap: () => cubit.toggleCluster(cluster.projectId),
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: Color(expanded ? primaryColor : grey5Color),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2),
                    child: Text(
                      cluster.projectName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _availableCount(cluster.totalAvailable),
              ],
            ),
          ),
        ),
      ),
      if (expanded)
        for (final product in cluster.products)
          ..._productTiles(cubit, state, cluster, product),
    ];
  }

  List<Widget> _productTiles(
    UnitPickerCubit cubit,
    UnitPickerState state,
    UnitCluster cluster,
    UnitProduct product,
  ) {
    final key = UnitPickerCubit.productKey(product);
    final expanded = state.expandedProducts.contains(key);
    final lots = state.lotsByProduct[key] ?? const <UnitLot>[];
    final contextLabel = [
      widget.page.townshipName ?? '',
      cluster.projectName,
      product.displayName,
    ].where((e) => e.isNotEmpty).join(' · ');
    final townshipId = cluster.townshipId != 0
        ? cluster.townshipId
        : widget.page.townshipId;

    _UnitChoice choice(
      String id,
      String label, {
      int? propertyId,
      String? unitMode,
    }) => _UnitChoice(
      key: '$id-${cluster.projectId}-${product.productId}',
      label: label,
      context: contextLabel,
      propertyId: propertyId,
      unitMode: unitMode,
      productId: product.productId,
      townshipId: townshipId,
      companyId: product.companyId,
    );

    return [
      InkWell(
        onTap: () => cubit.toggleProduct(product),
        borderRadius: BorderRadius.circular(9),
        child: Row(
          children: [
            Icon(
              expanded ? Icons.expand_more : Icons.chevron_right,
              size: 16,
              color: Color(expanded ? primaryColor : grey5Color),
            ),
            const SizedBox(width: 2),
            Expanded(child: _tipeHeader(product.displayName, product.spec ?? '')),
            const SizedBox(width: 8),
            _availableCount(product.totalAvailable),
          ],
        ),
      ),
      if (expanded) ...[
        _specialRow(
          choice('undecided', 'Belum menentukan kavling', unitMode: 'undecided'),
        ),
        _specialRow(
          choice('waiting', 'Waitinglist', unitMode: 'waiting'),
          waiting: true,
        ),
        if (state.loadingProductIds.contains(key))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          for (final lot in lots.where(
            (l) => (l.displayStatusName ?? 'Available') == 'Available',
          ))
            _kavlingRow(
              choice(
                'lot-${lot.propertyId}',
                lot.propertyName,
                propertyId: lot.propertyId,
              ),
            ),
      ],
    ];
  }

  Widget _tipeHeader(String tipe, String sub) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(grey11Color),
      borderRadius: BorderRadius.circular(9),
    ),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: tipe),
          TextSpan(
            text: '  $sub',
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(grey4Color),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _availableCount(int total) => Text(
    '$total tersedia',
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Color(total > 0 ? primaryColor : grey5Color),
    ),
  );

  void _pick(_UnitChoice choice) {
    if (_submitting) return;
    setState(() => _selected = _selected?.key == choice.key ? null : choice);
  }

  Widget _specialRow(_UnitChoice choice, {bool waiting = false}) {
    final selected = _selected?.key == choice.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => _pick(choice),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(roSelectedBgColor) : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              _checkbox(selected),
              const SizedBox(width: 10),
              Text(
                choice.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Color(waiting ? warningColor : grey4Color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kavlingRow(_UnitChoice choice) {
    final selected = _selected?.key == choice.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        onTap: () => _pick(choice),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(roSelectedBgColor) : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              _checkbox(selected),
              const SizedBox(width: 10),
              Expanded(
                child: Text(choice.label, style: const TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final selected = _selected;
    return Container(
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        border: Border(top: BorderSide(color: Color(grey10Color))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    selected == null
                        ? 'Belum ada unit dipilih'
                        : 'Unit pengganti: ${selected.label}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              customButton(
                _submitting ? null : _submit,
                _submitting ? 'Menyimpan…' : 'Ganti Unit & Ajukan Ulang',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final choice = _selected;
    if (choice == null) {
      setState(() => _tab = 'replacement');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih unit pengganti terlebih dahulu.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ganti Unit?'),
        content: Text(
          '${widget.page.currentUnitName} → ${choice.label}\n${choice.context}\n\n'
          'Reserve order akan langsung diajukan ulang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ganti Unit'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    final error = await context.read<ReserveOrderDetailCubit>().changeUnit(
      widget.page.reserveOrderId,
      ChangeReserveOrderUnitParams(
        propertyId: choice.propertyId,
        unitMode: choice.unitMode,
        productId: choice.productId,
        townshipId: choice.townshipId,
        companyId: choice.companyId,
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      showSnackbar(context, error, isError: true);
      return;
    }
    Navigator.of(context).pop(true);
  }
}
