import 'package:progress_group/features/contact/domain/entities/pameran/pameran_aktif_entity.dart';

class PameranAktifModel extends PameranAktifEntity {
  PameranAktifModel({
    required super.periodeId,
    required super.lokasiPameran,
    required super.periode,
    required super.startDate,
    required super.endDate,
  });

  factory PameranAktifModel.fromJson(Map<String, dynamic> json) {
    return PameranAktifModel(
      periodeId: json['periode_pameran_id'],
      lokasiPameran: json['lokasi_pameran'] ?? '',
      periode: json['periode'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }
}
