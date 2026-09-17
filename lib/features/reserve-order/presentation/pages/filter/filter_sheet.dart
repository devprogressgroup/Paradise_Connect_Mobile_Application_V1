import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/filter/filter_widgets.dart';

/// Bottom sheet filter status reserve — gaya visualnya disamakan dengan
/// `ContactFilterSheet` (kartu section rounded, header X/judul/Reset, baris opsi,
/// tombol "Terapkan" di bawah), dipakai menggantikan baris chip horizontal lama.
///
/// Cuma satu dimensi filter (status reserve) jadi tanpa accordion — section-nya
/// selalu terbuka. Single-select, sama seperti perilaku chip sebelumnya. Urutan
/// ("sort") sengaja BUKAN bagian dari sheet ini — itu tombol & sheet sendiri, lihat
/// `sort_sheet.dart`.
Future<List<int>?> showReserveOrderFilterSheet(
  BuildContext context, {
  required List<ReserveFilterOption> filters,
  required List<int> initialStatusIds,
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ReserveOrderFilterSheet(filters: filters, initialStatusIds: initialStatusIds),
  );
}

class ReserveOrderFilterSheet extends StatefulWidget {
  final List<ReserveFilterOption> filters;
  final List<int> initialStatusIds;

  const ReserveOrderFilterSheet({super.key, required this.filters, required this.initialStatusIds});

  @override
  State<ReserveOrderFilterSheet> createState() => _ReserveOrderFilterSheetState();
}

class _ReserveOrderFilterSheetState extends State<ReserveOrderFilterSheet> {
  int? _staged;

  @override
  void initState() {
    super.initState();
    _staged = widget.initialStatusIds.isEmpty ? null : widget.initialStatusIds.first;
  }

  int get _activeCount => _staged != null ? 1 : 0;

  void _reset() => setState(() => _staged = null);

  void _apply() => Navigator.pop(context, _staged == null ? const <int>[] : [_staged!]);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24),
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          reserveFilterSheetHandle(),
          _buildHeader(),
          const Divider(height: 1, color: Color(grey10Color)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: reserveFilterSectionCard(
                icon: Icons.flag_rounded,
                title: 'STATUS RESERVE',
                children: [
                  reserveFilterOptionRow('Semua', selected: _staged == null, onTap: () => setState(() => _staged = null)),
                  for (final filter in widget.filters)
                    reserveFilterOptionRow(
                      filter.name,
                      selected: _staged == filter.statusReserveId,
                      onTap: () => setState(() => _staged = filter.statusReserveId),
                    ),
                ],
              ),
            ),
          ),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Color(grey11Color), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 18, color: Color(grey1Color)),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(blue2Color))),
                if (_activeCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$_activeCount filter aktif',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(primaryColor)),
                  ),
                ],
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _activeCount > 0 ? _reset : null,
            icon: Icon(Icons.restart_alt_rounded, size: 16, color: _activeCount > 0 ? const Color(primaryColor) : const Color(grey7Color)),
            label: Text(
              'Reset',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _activeCount > 0 ? const Color(primaryColor) : const Color(grey7Color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        border: Border(top: BorderSide(color: Color(grey10Color))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('reserve_order_filter_apply'),
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _activeCount > 0 ? 'Terapkan ($_activeCount filter)' : 'Terapkan',
                style: const TextStyle(color: Color(whiteColor), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
