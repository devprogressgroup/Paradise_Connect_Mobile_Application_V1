import 'package:equatable/equatable.dart';

class ProspectStatusEntity extends Equatable {
  final int statusProspectId;
  final String statusValue;
  final String statusProspectName;

  
  
  
  final String group;

  
  
  final bool isVisitForm;

  
  
  final bool isVisitorWi;

  // Tahap yang DILEWATI bila kontak dipindah ke status ini (tanggalnya masih kosong).
  // Dihitung server per kontak (`skip_stages`, butuh contact_id) — kosong = tidak lompat tahap.
  final List<ProspectSkipStage> skipStages;

  const ProspectStatusEntity({
    required this.statusProspectId,
    required this.statusValue,
    required this.statusProspectName,
    this.group = 'db',
    this.isVisitForm = false,
    this.isVisitorWi = false,
    this.skipStages = const [],
  });

  @override
  List<Object?> get props =>
      [statusProspectId, statusValue, statusProspectName, group, isVisitForm, isVisitorWi, skipStages];
}

// Satu tahap yang dilewati: key = appt|visit|reserve|reserve_booking, label = nama tampilan.
class ProspectSkipStage extends Equatable {
  final String key;
  final String label;

  const ProspectSkipStage({required this.key, required this.label});

  @override
  List<Object?> get props => [key, label];
}
