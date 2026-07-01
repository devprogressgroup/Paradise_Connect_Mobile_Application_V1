import 'package:equatable/equatable.dart';

class ProspectStatusEntity extends Equatable {
  final int statusProspectId;
  final String statusValue;
  final String statusProspectName;

  /// Grup form mobile dari backend ('db'|'appt'|'visit'|'reserve'|'sp'|'lost').
  /// Menentukan template form Update Status yang ditampilkan (menggantikan daftar ID hardcoded).
  /// Sumber: setting STATUS_PROSPECT_* (lihat ProspectStage::formGroupMap di backend).
  final String group;

  /// True bila status boleh dipilih saat merekam Visit (page Visit).
  /// Sumber: setting STATUS_PROSPECT_APPOINTMENT_REALIZE (backend). Menggantikan daftar ID hardcoded [63,64,65].
  final bool isVisitForm;

  /// True bila status termasuk "Visitor/WI" (STATUS_PROSPECT_VISITOR_WI) → form Visit mengaktifkan
  /// input berapa kali datang (>1). Menggantikan hardcode `selectedStatusId == 65`.
  final bool isVisitorWi;

  const ProspectStatusEntity({
    required this.statusProspectId,
    required this.statusValue,
    required this.statusProspectName,
    this.group = 'db',
    this.isVisitForm = false,
    this.isVisitorWi = false,
  });

  @override
  List<Object?> get props =>
      [statusProspectId, statusValue, statusProspectName, group, isVisitForm, isVisitorWi];
}
