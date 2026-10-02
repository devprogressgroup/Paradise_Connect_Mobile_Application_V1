import '../../../domain/entities/prospect/prospect_status.dart';

class ProspectStatusModel extends ProspectStatusEntity {
  const ProspectStatusModel({
    required super.statusProspectId,
    required super.statusValue,
    required super.statusProspectName,
    super.group,
    super.isVisitForm,
    super.isVisitorWi,
    super.skipStages,
  });

  factory ProspectStatusModel.fromJson(Map<String, dynamic> json) {
    return ProspectStatusModel(
      statusProspectId: json['status_prospect_id'] as int,
      statusValue: json['status_value'] as String,
      statusProspectName: json['status_prospect_name'] as String,
      group: (json['group'] as String?)?.isNotEmpty == true ? json['group'] as String : 'db',
      isVisitForm: json['is_visit_form'] == true || json['is_visit_form'] == 1,
      isVisitorWi: json['is_visitor_wi'] == true || json['is_visitor_wi'] == 1,
      skipStages: (json['skip_stages'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => ProspectSkipStage(
                key: e['key'] as String,
                label: (e['label'] as String?) ?? e['key'] as String,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_prospect_id': statusProspectId,
      'status_value': statusValue,
      'status_prospect_name': statusProspectName,
      'group': group,
      'is_visit_form': isVisitForm,
      'is_visitor_wi': isVisitorWi,
      'skip_stages': skipStages.map((s) => {'key': s.key, 'label': s.label}).toList(),
    };
  }
}
