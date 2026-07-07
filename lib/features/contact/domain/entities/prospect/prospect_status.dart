import 'package:equatable/equatable.dart';

class ProspectStatusEntity extends Equatable {
  final int statusProspectId;
  final String statusValue;
  final String statusProspectName;

  
  
  
  final String group;

  
  
  final bool isVisitForm;

  
  
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
