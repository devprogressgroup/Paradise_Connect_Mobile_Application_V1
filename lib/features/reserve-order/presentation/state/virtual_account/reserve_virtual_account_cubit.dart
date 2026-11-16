import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/entities/property_virtual_account_entity.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_property_virtual_account_usecase.dart';
import 'reserve_virtual_account_state.dart';

/// Satu unit yang VA-nya mau ditampilkan di Review Create Reserve Order.
///
/// [companyId] & [propertyId] HARUS sama dengan `units[i][company_id]` / `units[i][property_id]`
/// yang dikirim ke `POST /reserve-order/create`; [townshipId] = project yang dipilih di wizard.
class VirtualAccountLookup {
  /// Identitas unit di wizard (`ReserveUnitOption.id`) — key status di state.
  final String unitKey;

  /// Nama unit untuk label blok (hanya tampilan).
  final String unitName;
  final int? townshipId;
  final int? companyId;
  final int? propertyId;

  const VirtualAccountLookup({
    required this.unitKey,
    required this.unitName,
    this.townshipId,
    this.companyId,
    this.propertyId,
  });

  /// Tanpa `property_id` = Waitinglist / Belum menentukan kavling.
  bool get hasKavling => propertyId != null;

  /// Semua parameter wajib terisi — `company_id` wajib (tanpa itu backend 422 `AMBIGUOUS_UNIT`).
  bool get isComplete =>
      (townshipId ?? 0) > 0 && (companyId ?? 0) > 0 && (propertyId ?? 0) > 0;

  String get cacheKey => '$townshipId|$companyId|$propertyId';

  /// Pembanding untuk tahu daftar unit berubah (bukan identitas cache).
  String get signature => '$unitKey|$cacheKey';
}

/// VA tiap unit untuk baris "Virtual Account" di Review Create Reserve Order.
///
/// - Hasil SUKSES di-cache per (township_id, company_id, property_id) selama satu sesi create
///   ([reset] dipanggil saat wizard dibuka / form direset). Error (termasuk 404) tidak di-cache,
///   jadi kembali ke Review = coba lagi.
/// - [load] dipanggil saat Review tampil, [cancel] saat Review ditinggalkan; respons dari
///   [load] sebelumnya diabaikan (dicek lewat generation).
/// - Murni tampilan — tidak menyentuh payload `POST /reserve-order/create`.
class ReserveVirtualAccountCubit extends Cubit<ReserveVirtualAccountState> {
  final GetPropertyVirtualAccountUseCase getPropertyVirtualAccountUseCase;

  ReserveVirtualAccountCubit({required this.getPropertyVirtualAccountUseCase})
    : super(const ReserveVirtualAccountState());

  final Map<String, List<VirtualAccountEntity>> _cache = {};
  int _generation = 0;

  void load(List<VirtualAccountLookup> lookups) {
    final generation = ++_generation;
    final units = <String, UnitVirtualAccountState>{};
    // Unit dgn key cache sama cukup 1 request.
    final pending = <String, List<VirtualAccountLookup>>{};

    for (final l in lookups) {
      if (!l.hasKavling) {
        units[l.unitKey] = const UnitVirtualAccountState(
          UnitVirtualAccountStatus.noKavling,
        );
      } else if (!l.isComplete) {
        units[l.unitKey] = const UnitVirtualAccountState(
          UnitVirtualAccountStatus.failed,
        );
      } else if (_cache.containsKey(l.cacheKey)) {
        units[l.unitKey] = UnitVirtualAccountState(
          UnitVirtualAccountStatus.loaded,
          accounts: _cache[l.cacheKey]!,
        );
      } else {
        units[l.unitKey] = const UnitVirtualAccountState(
          UnitVirtualAccountStatus.loading,
        );
        (pending[l.cacheKey] ??= []).add(l);
      }
    }

    emit(ReserveVirtualAccountState(units: units));

    // Paralel per unit.
    for (final group in pending.values) {
      unawaited(_fetch(generation, group));
    }
  }

  Future<void> _fetch(int generation, List<VirtualAccountLookup> group) async {
    final l = group.first;
    final result = await getPropertyVirtualAccountUseCase(
      townshipId: l.townshipId!,
      companyId: l.companyId!,
      propertyId: l.propertyId!,
    );
    // User sudah keluar dari Review / Review dibuka ulang → hasil lama diabaikan.
    if (isClosed || generation != _generation) return;

    final next = result.fold(
      (failure) => UnitVirtualAccountState(
        failure.isNotFound
            ? UnitVirtualAccountStatus.notFound
            : UnitVirtualAccountStatus.failed,
      ),
      (data) {
        _cache[l.cacheKey] = data.virtualAccounts;
        return UnitVirtualAccountState(
          UnitVirtualAccountStatus.loaded,
          accounts: data.virtualAccounts,
        );
      },
    );

    emit(
      ReserveVirtualAccountState(
        units: {
          ...state.units,
          for (final u in group) u.unitKey: next,
        },
      ),
    );
  }

  /// Review ditinggalkan — respons yang masih jalan diabaikan. Cache tetap.
  void cancel() => _generation++;

  /// Sesi create baru — kosongkan cache & status.
  void reset() {
    _generation++;
    _cache.clear();
    emit(const ReserveVirtualAccountState());
  }
}
