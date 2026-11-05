import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/reserve-order/domain/entities/property_virtual_account_entity.dart';

typedef VirtualAccountResult =
    Either<VirtualAccountFailure, PropertyVirtualAccountEntity>;

/// Section "Virtual Account" di bottom sheet detail unit Site Plan — hasil
/// `GET /property/virtual-account`. [future] dimulai oleh [UnitDetailPage] (paralel dengan
/// `/property-pricing`, supaya tidak ikut menunggu vendor harga yang lambat).
class UnitVirtualAccountSection extends StatelessWidget {
  final Future<VirtualAccountResult> future;
  final VoidCallback onRetry;

  const UnitVirtualAccountSection({
    super.key,
    required this.future,
    required this.onRetry,
  });

  static const _monoStyle = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Menlo', 'Courier New', 'Courier'],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Virtual Account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          decoration: BoxDecoration(
            color: const Color(whiteColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FutureBuilder<VirtualAccountResult>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _status('Memuat…', const Color(greyShade600));
              }
              final result = snapshot.data;
              if (result == null) return _failed();
              return result.fold(
                (failure) => failure.isNotFound
                    ? _status(
                        'Belum ada Virtual Account',
                        const Color(greyShade600),
                      )
                    : _failed(),
                (data) => data.virtualAccounts.isEmpty
                    ? _status(
                        'Belum ada Virtual Account',
                        const Color(greyShade600),
                      )
                    : Column(
                        children: [
                          for (final va in data.virtualAccounts) _row(va),
                        ],
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _status(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _failed() => Row(
    children: [
      Expanded(
        child: _status('Gagal memuat Virtual Account', const Color(redColor)),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          onTap: onRetry,
          child: const Text(
            'Coba lagi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(primaryColor),
            ),
          ),
        ),
      ),
    ],
  );

  /// Nama bank kiri, `virtual_account_full` kanan (monospace) — gaya sama dgn baris angsuran.
  Widget _row(VirtualAccountEntity va) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            va.bankName.isEmpty ? '-' : va.bankName,
            style: const TextStyle(fontSize: 12, color: Color(greyShade600)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          va.virtualAccountFull,
          style: _monoStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
