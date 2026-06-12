import '../../../domain/entities/prospect/prospect_status.dart';

class ProspectStatusModel extends ProspectStatusEntity {
  const ProspectStatusModel({
    required super.statusProspectId,
    required super.statusValue,
    required super.statusProspectName,
    
  });

  factory ProspectStatusModel.fromJson(Map<String, dynamic> json) {
    return ProspectStatusModel(
      statusProspectId: json['status_prospect_id'] as int,
      statusValue: json['status_value'] as String,
      statusProspectName: json['status_prospect_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_prospect_id': statusProspectId,
      'status_value': statusValue,
      'status_prospect_name': statusProspectName,
    };
  }
}
