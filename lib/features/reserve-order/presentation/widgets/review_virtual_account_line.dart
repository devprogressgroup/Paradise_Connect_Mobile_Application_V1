import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/reserve-order/domain/entities/property_virtual_account_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/state/virtual_account/reserve_virtual_account_cubit.dart';
import 'package:progress_group/features/reserve-order/presentation/state/virtual_account/reserve_virtual_account_state.dart';

/// Baris "Virtual Account" di kartu ringkasan Review Create Reserve Order — style sama dengan
/// baris ringkasan lain (label abu-abu kiri, nilai tebal rata kanan).
///
/// VA dimuat saat baris ini tampil (masuk Review) dan dibatalkan saat hilang (keluar Review) —
/// lihat [ReserveVirtualAccountCubit]. Hanya tampilan: gagal memuat tidak memblokir submit.
class ReviewVirtualAccountLine extends StatefulWidget {
  final List<VirtualAccountLookup> units;

  const ReviewVirtualAccountLine({super.key, required this.units});

  @override
  State<ReviewVirtualAccountLine> createState() =>
      _ReviewVirtualAccountLineState();
}

class _ReviewVirtualAccountLineState extends State<ReviewVirtualAccountLine> {
  late final ReserveVirtualAccountCubit _cubit;

  static const _monoStyle = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Menlo', 'Courier New', 'Courier'],
  );

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ReserveVirtualAccountCubit>();
    _cubit.load(widget.units);
  }

  @override
  void didUpdateWidget(covariant ReviewVirtualAccountLine oldWidget) {
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
                  builder: (context, state) {
                    final showUnitName = widget.units.length > 1;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < widget.units.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          if (showUnitName) _unitName(widget.units[i].unitName),
                          ..._values(state.units[widget.units[i].unitKey]),
                        ],
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _unitName(String name) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      name,
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 10.5, color: Color(grey4Color)),
    ),
  );

  List<Widget> _values(UnitVirtualAccountState? unit) {
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
        return [for (final va in unit.accounts) _account(va)];
    }
  }

  Widget _status(String text, Color color) => Text(
    text,
    textAlign: TextAlign.right,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
  );

  /// `{bank_name} · {virtual_account_full}` — nomor pakai font monospace.
  Widget _account(VirtualAccountEntity va) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: RichText(
      textAlign: TextAlign.right,
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(blackColor),
        ),
        children: [
          if (va.bankName.isNotEmpty) TextSpan(text: '${va.bankName} · '),
          TextSpan(text: va.virtualAccountFull, style: _monoStyle),
        ],
      ),
    ),
  );
}
