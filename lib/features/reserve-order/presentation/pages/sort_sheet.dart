import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/filter/filter_widgets.dart';

/// Opsi `sort` yang didukung `GET /api/reserve` — urutan ini juga urutan tampil di sheet.
const List<(String value, String label)> reserveOrderSortOptions = [
  ('created_desc', 'Terbaru'),
  ('created_asc', 'Terlama'),
  ('name_asc', 'Nama A-Z'),
  ('name_desc', 'Nama Z-A'),
  ('amount_desc', 'Harga Tertinggi'),
  ('amount_asc', 'Harga Terendah'),
];

const String reserveOrderDefaultSort = 'created_desc';

String reserveOrderSortLabel(String value) {
  for (final option in reserveOrderSortOptions) {
    if (option.$1 == value) return option.$2;
  }
  return reserveOrderSortOptions.first.$2;
}

/// Bottom sheet "Urutkan" — tombol pemicu & sheet-nya sengaja terpisah dari
/// [showReserveOrderFilterSheet] (bukan section di dalam sheet Filter), sama seperti pola
/// "Dibuat: Terbaru" di Contacts yang jadi tombol sendiri, terpisah dari tombol "Filter".
/// Single-select, langsung diterapkan begitu satu opsi ditekan (tanpa tombol "Terapkan").
Future<String?> showReserveOrderSortSheet(BuildContext context, {required String currentSort}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReserveOrderSortSheet(currentSort: currentSort),
  );
}

class _ReserveOrderSortSheet extends StatelessWidget {
  final String currentSort;

  const _ReserveOrderSortSheet({required this.currentSort});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24),
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            reserveFilterSheetHandle(),
            _buildHeader(context),
            const Divider(height: 1, color: Color(grey10Color)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: reserveFilterSectionCard(
                  icon: Icons.swap_vert_rounded,
                  title: 'URUTKAN',
                  children: [
                    for (final option in reserveOrderSortOptions)
                      reserveFilterOptionRow(
                        option.$2,
                        selected: currentSort == option.$1,
                        onTap: () => Navigator.pop(context, option.$1),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          const Expanded(
            child: Text(
              'Urutkan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(blue2Color)),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
