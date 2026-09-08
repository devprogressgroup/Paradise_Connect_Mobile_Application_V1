import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_type.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/upload_attachment_params.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/get_attachment_types_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/upload_attachment_usecase.dart';
import 'reserve_attachment_state.dart';

/// Satu kelompok berkas Reserve Order yang dikirim dalam satu request `POST
/// /contacts/{id}/attachments` — semua berkas di dalamnya memakai attachment type yang sama.
class ReserveAttachmentGroup {
  /// Nama yang dipakai di pesan error, mis. "KTP".
  final String label;

  /// Kata kunci pencarian nama attachment type, dicoba berurutan sampai ketemu. Master datanya
  /// dikelola di CRM, jadi id-nya tidak di-hardcode di app.
  final List<String> typeKeywords;

  final List<Uint8List> bytes;
  final List<String> fileNames;

  const ReserveAttachmentGroup({
    required this.label,
    required this.typeKeywords,
    required this.bytes,
    required this.fileNames,
  });
}

/// Mengunggah dokumen Reserve Order (KTP, NPWP, bukti bayar) ke attachment kontak.
///
/// Semua berkas ditahan di halaman Reserve sampai tombol **Submit Reserve Order** ditekan, baru
/// dikirim sekaligus lewat cubit ini — supaya tidak ada attachment nyangkut di kontak kalau
/// flow-nya dibatalkan di tengah jalan.
class ReserveAttachmentCubit extends Cubit<ReserveAttachmentState> {
  final GetAttachmentTypesUseCase getTypesUseCase;
  final UploadAttachmentUseCase uploadUseCase;

  /// Master attachment type di-cache karena isinya jarang berubah dan dipakai berulang setiap
  /// submit.
  List<AttachmentType>? _types;

  ReserveAttachmentCubit(this.getTypesUseCase, this.uploadUseCase) : super(const ReserveAttachmentState());

  /// Mengirim semua [groups]; mengembalikan true kalau seluruhnya berhasil. Kegagalan di satu
  /// kelompok menghentikan sisanya — statusnya jadi error dengan pesan yang menyebut dokumennya.
  Future<bool> submit({
    required int contactId,
    int? dealId,
    required String note,
    required List<ReserveAttachmentGroup> groups,
  }) async {
    final pending = groups.where((g) => g.bytes.isNotEmpty).toList();
    if (pending.isEmpty) return true;

    final total = pending.fold<int>(0, (sum, g) => sum + g.bytes.length);
    emit(ReserveAttachmentState(status: ReserveAttachmentStatus.loading, total: total));

    final types = await _loadTypes();
    if (types == null) return false;

    var uploaded = 0;
    for (final group in pending) {
      final typeId = _findTypeId(types, group.typeKeywords);
      if (typeId == null) {
        emit(state.copyWith(
          status: ReserveAttachmentStatus.error,
          error: 'Attachment type untuk ${group.label} tidak ada di master data. Tambahkan dulu di CRM.',
        ));
        return false;
      }

      final result = await uploadUseCase(UploadAttachmentParams(
        contactId: contactId,
        dealId: dealId,
        attachmentTypeId: typeId,
        attachmentNote: note,
        filesBytesList: group.bytes,
        fileNames: group.fileNames,
      ));

      final failure = result.fold((error) => error, (_) => null);
      if (failure != null) {
        emit(state.copyWith(
          status: ReserveAttachmentStatus.error,
          error: 'Gagal mengunggah ${group.label}: ${cleanErrorMessage(failure)}',
        ));
        return false;
      }

      uploaded += group.bytes.length;
      emit(state.copyWith(uploaded: uploaded));
    }

    emit(state.copyWith(status: ReserveAttachmentStatus.loaded, uploaded: uploaded));
    return true;
  }

  Future<List<AttachmentType>?> _loadTypes() async {
    final cached = _types;
    if (cached != null && cached.isNotEmpty) return cached;

    final result = await getTypesUseCase();
    return result.fold(
      (error) {
        emit(state.copyWith(
          status: ReserveAttachmentStatus.error,
          error: 'Gagal memuat attachment type: ${cleanErrorMessage(error)}',
        ));
        return null;
      },
      (data) {
        _types = data;
        return data;
      },
    );
  }

  /// Kata kunci dicoba berurutan supaya yang paling spesifik menang duluan — "Bukti Transfer"
  /// dipilih sebelum tipe umum yang cuma bernama "Bukti".
  int? _findTypeId(List<AttachmentType> types, List<String> keywords) {
    for (final keyword in keywords) {
      for (final type in types) {
        if (type.name.toLowerCase().contains(keyword.toLowerCase())) return type.id;
      }
    }
    return null;
  }

  void reset() => emit(const ReserveAttachmentState());
}
