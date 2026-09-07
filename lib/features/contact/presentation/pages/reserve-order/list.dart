import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/core/utils/widget/shimmer_loading.dart';
import 'package:progress_group/features/contact/data/models/reserve/reserve_order_model.dart';
import 'package:progress_group/features/contact/presentation/pages/reserve-order/widgets.dart';
import 'package:progress_group/features/contact/presentation/state/reserve_order_list/reserve_order_list_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/reserve_order_list/reserve_order_list_state.dart';

/// Menu "Reserve Order" dari drawer — list transaksi dari `GET /api/reserve`.
/// Mockup: `reserve-order-sales-final_12.html` Bagian 3, kolom "List Reserve Order".
class ReserveOrderListPage extends StatefulWidget {
  const ReserveOrderListPage({super.key});

  @override
  State<ReserveOrderListPage> createState() => _ReserveOrderListPageState();
}

class _ReserveOrderListPageState extends State<ReserveOrderListPage> {
  final searchTC = TextEditingController();
  final searchFN = FocusNode();
  final _scroll = ScrollController();

  Timer? _searchDebounce;

  // Filternya jalan di app (lihat catatan di ReserveOrderFilter) — bukan dikirim ke server, jadi
  // cukup state lokal, tidak lewat cubit.
  ReserveOrderFilter _filter = ReserveOrderFilter.semua;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('reserve_order_list');
    _scroll.addListener(_onScroll);
    context.read<ReserveOrderListCubit>().load();
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
                    hintText: 'Cari nama / unit...',
                    onChanged: _onSearchChanged,
                  ),
                ),
                _buildFilters(),
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
            state.status == ReserveOrderListStatus.loaded ? '${state.total} transaksi' : 'Memuat transaksi...',
            style: const TextStyle(fontSize: 11, color: Color(grey4Color)),
          ),
        ],
      ),
    );
  }

  /// Baris chip Semua/Reserve/RBA/RBB/SP/Proses Bank/Akad — desainnya tetap tampil sesuai mockup
  /// meski sebagian kategorinya belum bisa terisi (lihat catatan di `ReserveOrderFilter`).
  Widget _buildFilters() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        key: const ValueKey('reserve_order_filter_list'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ReserveOrderFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ReserveOrderFilter.values[index];
          // Key sendiri karena beberapa label chip ("SP", "Akad") bisa sama persis dengan teks
          // badge status di kartu — tanpa ini finder di test jadi ambigu.
          return KeyedSubtree(
            key: ValueKey('reserve_order_filter_${filter.name}'),
            child: roChip(filter.label, _filter == filter, () {
              AnalyticsService.logEvent('reserve_order_list_filter');
              setState(() => _filter = filter);
            }),
          );
        },
      ),
    );
  }

  Widget _buildBody(ReserveOrderListState state) {
    return switch (state.status) {
      ReserveOrderListStatus.initial || ReserveOrderListStatus.loading => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: buildContactListShimmer(),
        ),
      ReserveOrderListStatus.error => _buildMessage(
          state.error ?? 'Gagal memuat reserve order',
          action: 'Coba lagi',
          onAction: () => context.read<ReserveOrderListCubit>().refresh(),
        ),
      ReserveOrderListStatus.loaded => _buildLoaded(state),
    };
  }

  Widget _buildLoaded(ReserveOrderListState state) {
    final filtered = state.items.where((o) => _filter.matches(o.status)).toList();

    if (filtered.isEmpty) {
      final String message;
      if (state.items.isEmpty) {
        message = state.search.isEmpty ? 'Belum ada transaksi reserve order.' : 'Tidak ada transaksi yang cocok dengan "${state.search}".';
      } else {
        // Ada transaksi, tapi tersaring habis oleh chip — beda pesan supaya jelas ini soal filter,
        // bukan soal pencarian.
        message = 'Tidak ada transaksi untuk filter "${_filter.label}".';
      }
      return _buildMessage(message);
    }

    return _buildList(state, filtered);
  }

  Widget _buildList(ReserveOrderListState state, List<ReserveOrder> items) {
    return RefreshIndicator(
      onRefresh: () => context.read<ReserveOrderListCubit>().refresh(),
      child: ListView.builder(
        controller: _scroll,
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
          return _buildCard(items[index]);
        },
      ),
    );
  }

  Widget _buildMessage(String message, {String? action, VoidCallback? onAction}) {
    return Center(
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
    );
  }

  Widget _buildCard(ReserveOrder order) {
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
                roStatusBadge(order.badgeLabel, order.status.color),
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
