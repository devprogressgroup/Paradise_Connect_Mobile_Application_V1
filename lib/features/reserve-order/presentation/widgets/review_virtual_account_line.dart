import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/reserve-order/domain/entities/property_virtual_account_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/state/virtual_account/reserve_virtual_account_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/virtual_account/reserve_virtual_account_state.dart';
import 'package:progress_group/features/reserve-order/presentation/widgets/virtual_account_copy_button.dart';

/// Pemuat VA untuk SELURUH Review Create Reserve Order — dipasang 1x membungkus isi Review.
///
/// VA SEMUA unit dimuat saat Review tampil dan dibatalkan saat Review ditinggalkan — lihat
/// [ReserveVirtualAccountCubit]. Sengaja dipisah dari [ReviewVirtualAccountLine]:
/// [ReserveVirtualAccountCubit.load] menaikkan generation & mengganti seluruh state, jadi kalau
/// tiap kartu unit memanggil `load()` sendiri, kartu berikutnya membatalkan hasil kartu
/// sebelumnya (tertahan di "Memuat…").
class ReviewVirtualAccountLoader extends StatefulWidget {
  final List<VirtualAccountLookup> units;
  final Widget child;

  const ReviewVirtualAccountLoader({
    super.key,
    required this.units,
    required this.child,
  });

  @override
  State<ReviewVirtualAccountLoader> createState() =>
      _ReviewVirtualAccountLoaderState();
}

class _ReviewVirtualAccountLoaderState
    extends State<ReviewVirtualAccountLoader> {
  late final ReserveVirtualAccountCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ReserveVirtualAccountCubit>();
    _cubit.load(widget.units);
  }

  @override
  void didUpdateWidget(covariant ReviewVirtualAccountLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.units) != _signature(widget.units)) {
      _cubit.load(widget.units);
    }
  }

  @override
  void dispose() {
    _cubit.cancel();
    super.dispose();
  }

  String _signature(List<VirtualAccountLookup> units) =>
      units.map((u) => u.signature).join(',');

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Baris "Virtual Account" di kartu unit Review Create Reserve Order — style sama dengan baris
/// review lain (label abu-abu kiri, nilai tebal rata kanan, garis bawah).
///
/// Hanya MEMBACA status VA unit [unitKey] dari [ReserveVirtualAccountCubit]; pemuatan dilakukan
/// [ReviewVirtualAccountLoader]. Hanya tampilan: gagal memuat tidak memblokir submit.
class ReviewVirtualAccountLine extends StatelessWidget {
  /// `VirtualAccountLookup.unitKey` unit ini (= `ReserveUnitOption.id`).
  final String unitKey;

  const ReviewVirtualAccountLine({super.key, required this.unitKey});

  static const _monoStyle = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Menlo', 'Courier New', 'Courier'],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(grey10Color))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Virtual Account',
            style: TextStyle(fontSize: 12, color: Color(grey1Color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                BlocBuilder<
                  ReserveVirtualAccountCubit,
                  ReserveVirtualAccountState
                >(
                  buildWhen: (prev, next) =>
                      prev.units[unitKey] != next.units[unitKey],
                  builder: (context, state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _values(context, state.units[unitKey]),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _values(BuildContext context, UnitVirtualAccountState? unit) {
    switch (unit?.status) {
      case null:
      case UnitVirtualAccountStatus.loading:
        return [_status('Memuat…', Color(grey4Color))];
      case UnitVirtualAccountStatus.noKavling:
        return [_status('Kavling belum ditentukan', Color(grey4Color))];
      case UnitVirtualAccountStatus.notFound:
        return [_status('Belum ada Virtual Account', Color(grey4Color))];
      case UnitVirtualAccountStatus.failed:
        return [_status('Gagal memuat Virtual Account', Color(redColor))];
      case UnitVirtualAccountStatus.loaded:
        if (unit!.accounts.isEmpty) {
          return [_status('Belum ada Virtual Account', Color(grey4Color))];
        }
        return [
          for (final (i, va) in unit.accounts.indexed)
            _account(context, va, isFirst: i == 0),
        ];
    }
  }

  Widget _status(String text, Color color) => Text(
    text,
    textAlign: TextAlign.right,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
  );

  /// Satu blok per VA, rata kanan: nama bank (kecil, abu-abu) di atas, `virtual_account_full`
  /// (monospace, tebal) di bawahnya; tombol salin di kanan blok.
  Widget _account(
    BuildContext context,
    VirtualAccountEntity va, {
    required bool isFirst,
  }) => Padding(
    padding: EdgeInsets.only(top: isFirst ? 0 : 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (va.bankName.isNotEmpty)
                Text(
                  va.bankName,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: Color(grey4Color)),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 4),
                  VirtualAccountCopyButton(
                    number: va.virtualAccountFull,
                    onCopied: () => _showCopied(context, va),
                  ),
                  Text(
                    va.virtualAccountFull,
                    textAlign: TextAlign.right,
                    style: _monoStyle.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(blackColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
       
      ],
    ),
  );

  /// SnackBar konfirmasi — aman di sini karena Review adalah halaman biasa (bukan bottom sheet).
  void _showCopied(BuildContext context, VirtualAccountEntity va) {
    if (!context.mounted) return;
    final bank = va.bankName.isEmpty ? '' : ' ${va.bankName}';
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    showSnackbar(
      context,
      'Nomor VA$bank disalin: ${va.virtualAccountFull}',
      duration: const Duration(seconds: 2),
    );
  }
}
