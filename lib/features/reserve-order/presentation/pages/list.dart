import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/reserve.dart';
import 'package:progress_group/features/reserve-order/presentation/pages/widgets.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_list/reserve_order_list_state.dart';

/// Menu "Reserve Order" — list transaksi dari `GET /api/reserve`.
/// Mockup: `reserve-order-sales-final_12.html` Bagian 3, kolom "List Reserve Order".
///
/// Dipakai di dua tempat: drawer ([contactArgs] null, semua transaksi) dan "Reserve Order" di Log
/// Activity kontak ([contactArgs] terisi, daftar disaring `contact_id` — lihat router.dart).
class ReserveOrderListPage extends StatefulWidget {
  final ContactDetailArgs? contactArgs;

  const ReserveOrderListPage({super.key, this.contactArgs});

  @override
  State<ReserveOrderListPage> createState() => _ReserveOrderListPageState();
}

class _ReserveOrderListPageState extends State<ReserveOrderListPage> {
  final searchTC = TextEditingController();
  final searchFN = FocusNode();
  final _scroll = ScrollController();

  Timer? _searchDebounce;

  int? get _contactId => widget.contactArgs?.dataContact?.contactId;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_list');
    _scroll.addListener(_onScroll);
    context.read<ReserveOrderListCubit>().loadFresh(contactId: _contactId);
  }

  @override
  void dispose() {
    searchTC.dispose();
    searchFN.dispose();
    _searchDebounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    // Ambil halaman berikutnya sebelum benar-benar mentok supaya scroll-nya tidak tersendat.
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      context.read<ReserveOrderListCubit>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      AnalyticsService.logEvent('reserve_order_list_search');
      context.read<ReserveOrderListCubit>().load(search: value.trim());
    });
  }

  Future<void> _openDetail(ReserveOrder order) async {
    AnalyticsService.logEvent('reserve_order_list_open_detail');
    await context.pushNamed('reserveOrderDetail', extra: order);
    // Detail bisa menambah catatan / mengajukan top up, jadi kartunya digambar ulang saat kembali.
    if (mounted) setState(() {});
  }

  /// Kontak yang belum pernah reserve (`total` 0 dari `/api/reserve?contact_id=...`) langsung
  /// ditawari bikin baru, ketimbang cuma menampilkan daftar kosong tanpa jalan keluar — dulu jalur
  /// ini ada di menu per-kontak lama (`ReserveOrderPage`/tile "Reserve").
  Future<void> _openCreateReserve() async {
    final args = widget.contactArgs;
    if (args == null) return;

    AnalyticsService.logEvent('reserve_order_list_create');
    final result = await context.pushNamed('reserveOrderReserve', extra: args.copyWith(namePage: 'Reserve'));
    if (!mounted) return;
    if (result is ReserveResult) context.read<ReserveOrderListCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(grey11Color),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ReserveOrderListCubit, ReserveOrderListState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildAppBar(state),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: customSearchField(
                    controller: searchTC,
                    focusNode: searchFN,
                    hintText: 'Search name / unit...',
                    onChanged: _onSearchChanged,
                  ),
                ),
                _buildFilters(state),
                const SizedBox(height: 10),
                Expanded(child: _buildBody(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(ReserveOrderListState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: const Color(whiteColor),
        border: Border(bottom: BorderSide(color: const Color(grey10Color))),
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
            // Angkanya dari `total` response, bukan dari jumlah baris yang sudah dimuat.
            state.status == ReserveOrderListStatus.loaded
                ? '${state.total} transaction${state.total == 1 ? '' : 's'}'
                : 'Loading transactions...',
            style: const TextStyle(fontSize: 11, color: Color(grey4Color)),
          ),
        ],
      ),
    );
  }

  /// Baris chip status dari `GET /api/reserve-filter` (master status reserve), plus "Semua" —
  /// pseudo-chip di app buat reset filter. Filternya jalan di server lewat `status_reserve_id`,
  /// bukan disaring di app lagi.
  Widget _buildFilters(ReserveOrderListState state) {
    if (state.filters.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: ListView.separated(
        key: const ValueKey('reserve_order_filter_list'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.filters.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return KeyedSubtree(
              key: const ValueKey('reserve_order_filter_semua'),
              child: roChip('All', state.statusIds.isEmpty, () => _onFilterTap(const [])),
            );
          }

          final filter = state.filters[index - 1];
          // Key pakai id, bukan nama — nama status bisa sama persis dengan teks badge di kartu.
          return KeyedSubtree(
            key: ValueKey('reserve_order_filter_${filter.statusReserveId}'),
            child: roChip(filter.name, state.statusIds.contains(filter.statusReserveId), () => _onFilterTap([filter.statusReserveId])),
          );
        },
      ),
    );
  }

  void _onFilterTap(List<int> statusIds) {
    AnalyticsService.logEvent('reserve_order_list_filter');
    context.read<ReserveOrderListCubit>().load(statusIds: statusIds);
  }

  Widget _buildBody(ReserveOrderListState state) {
    return switch (state.status) {
      ReserveOrderListStatus.initial || ReserveOrderListStatus.loading => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: buildContactListShimmer(),
        ),
      ReserveOrderListStatus.error => _buildMessage(
          state.error ?? 'Failed to load reserve order',
          action: 'Retry',
          onAction: () => context.read<ReserveOrderListCubit>().refresh(),
        ),
      ReserveOrderListStatus.loaded => _buildLoaded(state),
    };
  }

  Widget _buildLoaded(ReserveOrderListState state) {
    if (state.items.isNotEmpty) return _buildList(state, state.items);

    // Kontak ini belum pernah reserve sama sekali — tawarkan bikin baru ketimbang cuma pesan
    // kosong. Bukan saat pencarian/filter aktif, supaya tidak salah tempat.
    if (widget.contactArgs != null && state.search.isEmpty && state.statusIds.isEmpty) {
      return _buildMessage(
        'This contact has no reserve order transactions yet.',
        action: '+ Create New Reserve',
        onAction: _openCreateReserve,
      );
    }

    final String message;
    if (state.statusIds.isNotEmpty) {
      // Nama status dari chip yang aktif — beda dari pesan pencarian supaya jelas ini soal filter.
      final names = state.filters.where((f) => state.statusIds.contains(f.statusReserveId)).map((f) => f.name).join(', ');
      message = 'No transactions for filter "$names".';
    } else if (state.search.isNotEmpty) {
      message = 'No transactions matching "${state.search}".';
    } else {
      message = 'No reserve order transactions yet.';
    }
    return _buildMessage(message);
  }

  Widget _buildList(ReserveOrderListState state, List<ReserveOrder> items) {
    return RefreshIndicator(
      onRefresh: () => context.read<ReserveOrderListCubit>().refresh(),
      child: ListView.builder(
        controller: _scroll,
        // Tanpa ini, list yang isinya cuma 1-2 kartu (muat semua di layar tanpa perlu scroll)
        // bikin gesture tarik-refresh tidak kedeteksi — ListView baru scrollable kalau kontennya
        // meluber, defaultnya bukan `AlwaysScrollableScrollPhysics`.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        // Infinite scroll tetap mengambil halaman berikutnya dari data mentah (`state.items`),
        // supaya kategori yang sedang difilter bisa kebagian baris baru begitu dimuat.
        itemCount: items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          return _buildCard(items[index], state.filters);
        },
      ),
    );
  }

  // Dibungkus RefreshIndicator + scrollable juga (bukan cuma `_buildList`) supaya state kosong
  // ("belum ada transaksi" / hasil filter kosong) & error tetap bisa ditarik-refresh, bukan cuma
  // andalkan tombol "Retry". `LayoutBuilder` + `ConstrainedBox(minHeight: ...)` dipakai supaya
  // pesannya tetap di tengah layar walau kontennya pendek (`Center` biasa tidak scrollable).
  Widget _buildMessage(String message, {String? action, VoidCallback? onAction}) {
    return RefreshIndicator(
      onRefresh: () => context.read<ReserveOrderListCubit>().refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Color(grey4Color)),
                      ),
                      if (action != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: onAction,
                          child: Text(
                            action,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(primaryColor)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(ReserveOrder order, List<ReserveFilterOption> filters) {
    return InkWell(
      onTap: () => _openDetail(order),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(whiteColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(grey10Color)),
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
                roStatusBadge(order.badgeLabelFrom(filters), order.badgeColorFrom(filters)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.home_outlined, size: 14, color: Color(grey4Color)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: order.unitLabel,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(blue2Color)),
                      children: [
                        if (order.unitSub.isNotEmpty)
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
                _meta(Icons.person_outline, order.salesName),
                if (order.amountShort != null) _meta(Icons.savings_outlined, order.amountShort!),
                _meta(Icons.calendar_today_outlined, order.dateLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(grey4Color)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10.5, color: Color(grey4Color))),
      ],
    );
  }
}
