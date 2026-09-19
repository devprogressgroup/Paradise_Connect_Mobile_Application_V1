import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/helpers/number_helper.dart';
import 'package:progress_group/core/utils/widget/custom_filter_button.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_list_dummy_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_list_item.dart';

import '../create/index.dart';
import '../detail/index.dart';

/// Menu "Reserve Order" — halaman list transaksi.
///
/// Catatan: sementara masih pakai data contoh ([ReserveOrderListDummyDataSource]), belum
/// disambungkan ke API asli. Struktur & data mengikuti prototype `reserve-order-prototype (1).html`
/// (bagian LIST) biar gampang disambung ke datasource sungguhan nanti.
class ReserveOrderListPage extends StatefulWidget {
  const ReserveOrderListPage({super.key});

  @override
  State<ReserveOrderListPage> createState() => _ReserveOrderListPageState();
}

class _ReserveOrderListPageState extends State<ReserveOrderListPage> {
  static const _defaultSort = 'created_desc';

  static const _sortOptions = <MapEntry<String, String>>[
    MapEntry('created_desc', 'Dibuat: Terbaru'),
    MapEntry('created_asc', 'Dibuat: Terlama'),
    MapEntry('name_asc', 'Nama: A-Z'),
    MapEntry('name_desc', 'Nama: Z-A'),
  ];

  static const _statusOptions = <String>[
    'Diproses',
    'RBA',
    'RBB',
    'SP',
    'Proses Bank',
    'SPK',
    'Akad/PPJB ✓',
    'Ditolak',
  ];

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  final _items = const ReserveOrderListDummyDataSource().getAll();

  String _search = '';
  String _sort = _defaultSort;
  final Set<String> _statusFilter = {};

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_list');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<ReserveOrderListItem> get _visibleItems {
    final term = _search.trim().toLowerCase();
    final list = _items.where((o) {
      final matchTerm = term.isEmpty ||
          o.customerName.toLowerCase().contains(term) ||
          o.unitName.toLowerCase().contains(term);
      final matchStatus = _statusFilter.isEmpty || _statusFilter.contains(o.status);
      return matchTerm && matchStatus;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case 'created_asc':
          return a.createdAt.compareTo(b.createdAt);
        case 'name_asc':
          return a.customerName.compareTo(b.customerName);
        case 'name_desc':
          return b.customerName.compareTo(a.customerName);
        case 'created_desc':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;
    return Scaffold(
      backgroundColor: const Color(grey11Color),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: customSearchField(
                controller: _searchController,
                focusNode: _searchFocus,
                hintText: 'Cari nama / unit...',
                onChanged: (value) {
                  AnalyticsService.logEvent('reserve_order_list_search');
                  setState(() => _search = value);
                },
              ),
            ),
            _buildFilterRow(),
            Expanded(child: _buildBody(visible)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          onPressed: () {
            AnalyticsService.logEvent('reserve_order_list_fab_create');
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateReserveOrderPage()),
            );
          },
          backgroundColor: const Color(primaryColor),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Color(whiteColor)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Color(whiteColor),
        border: Border(bottom: BorderSide(color: Color(grey10Color))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reserve Order',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(blue2Color)),
          ),
          const SizedBox(height: 2),
          Text(
            '${_items.length} transaksi aktif',
            style: const TextStyle(fontSize: 11, color: Color(grey4Color)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final sortLabel = _sortOptions.firstWhere((e) => e.key == _sort).value;
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CustomFilterButton(
              key: const ValueKey('reserve_order_sort_button'),
              label: sortLabel,
              isSelected: _sort != _defaultSort,
              onTap: _openSortSheet,
              onClear: _sort != _defaultSort ? () => setState(() => _sort = _defaultSort) : null,
            ),
            const SizedBox(width: 8),
            CustomFilterButton(
              key: const ValueKey('reserve_order_filter_button'),
              label: _statusFilter.isEmpty ? 'Filter' : _statusFilter.length == 1 ? _statusFilter.first : '${_statusFilter.length} Status',
              isSelected: _statusFilter.isNotEmpty,
              onTap: _openFilterSheet,
              onClear: _statusFilter.isNotEmpty ? () => setState(_statusFilter.clear) : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSortSheet() async {
    AnalyticsService.logEvent('reserve_order_list_sort');
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SortSheet(options: _sortOptions, current: _sort),
    );
    if (result != null) setState(() => _sort = result);
  }

  Future<void> _openFilterSheet() async {
    AnalyticsService.logEvent('reserve_order_list_filter');
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterSheet(options: _statusOptions, initial: _statusFilter),
    );
    if (result != null) setState(() {
      _statusFilter
        ..clear()
        ..addAll(result);
    });
  }

  Widget _buildBody(List<ReserveOrderListItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Tidak ada Reserve Order yang cocok dengan pencarian/filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(grey4Color)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildCard(items[index]),
    );
  }

  Widget _buildCard(ReserveOrderListItem order) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        AnalyticsService.logEvent('reserve_order_list_open_detail');
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReserveOrderDetailPage(initiallyRejected: order.status == 'Ditolak')),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: const Color(blackColor).withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(blue2Color)),
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(order.status, order.statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏠', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: order.unitName,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(blue2Color)),
                      children: [
                        TextSpan(
                          text: '\n${order.unitSub}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(grey4Color)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _meta('👤', order.salesName),
                _meta('💰', 'Rp ${NumberHelper.thousands(order.amount)}'),
                _meta('💼', order.category),
                _meta('📅', order.dateLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: const TextStyle(color: Color(whiteColor), fontSize: 10.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _meta(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 10.5)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10.5, color: Color(grey4Color))),
      ],
    );
  }
}

class _SortSheet extends StatelessWidget {
  final List<MapEntry<String, String>> options;
  final String current;

  const _SortSheet({required this.options, required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Urutkan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(blue2Color))),
            ),
            for (final option in options)
              InkWell(
                onTap: () => Navigator.of(context).pop(option.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: option.key == current ? const Color(primaryColor) : const Color(blue2Color),
                          fontWeight: option.key == current ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                      if (option.key == current) const Icon(Icons.check, size: 18, color: Color(primaryColor)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> options;
  final Set<String> initial;

  const _FilterSheet({required this.options, required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(whiteColor),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(blue2Color))),
                InkWell(
                  onTap: () => setState(_selected.clear),
                  child: const Text('↻ Reset', style: TextStyle(fontSize: 12, color: Color(primaryColor), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final status in widget.options)
              InkWell(
                onTap: () => setState(() {
                  if (!_selected.add(status)) _selected.remove(status);
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _selected.contains(status) ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 20,
                        color: _selected.contains(status) ? const Color(primaryColor) : const Color(grey7Color),
                      ),
                      const SizedBox(width: 10),
                      Text(status, style: const TextStyle(fontSize: 13, color: Color(blue2Color))),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: const Text('Terapkan Filter', style: TextStyle(color: Color(whiteColor), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

