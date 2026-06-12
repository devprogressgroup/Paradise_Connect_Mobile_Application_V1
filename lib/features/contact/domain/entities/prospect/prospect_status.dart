import 'package:equatable/equatable.dart';

class ProspectStatusEntity extends Equatable {
  final int statusProspectId;
  final String statusValue;
  final String statusProspectName;

  const ProspectStatusEntity({
    required this.statusProspectId,
    required this.statusValue,
    required this.statusProspectName,
  });

  @override
  List<Object?> get props => [statusProspectId, statusValue, statusProspectName];
}
