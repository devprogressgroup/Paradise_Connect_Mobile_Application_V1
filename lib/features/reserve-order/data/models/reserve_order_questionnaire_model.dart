import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_questionnaire_entity.dart';

class ReserveQuestionnaireModel extends ReserveQuestionnaireEntity {
  const ReserveQuestionnaireModel({super.questions, super.filledDate});

  factory ReserveQuestionnaireModel.fromJson(Map<String, dynamic> json) {
    return ReserveQuestionnaireModel(
      filledDate: json['filled_date']?.toString(),
      questions: ((json['questions'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_question)
          .toList(),
    );
  }

  static ReserveQuestionEntity _question(Map<String, dynamic> json) {
    // `is Map` — PHP bisa kirim `[]` (bukan null) kalau kosong.
    final depends = json['depends'] is Map<String, dynamic>
        ? json['depends'] as Map<String, dynamic>
        : null;
    final answer = (json['answer'] as String?)?.trim() ?? '';
    return ReserveQuestionEntity(
      title: json['title'] as String? ?? '',
      text: json['text'] as String?,
      layout: json['layout'] as String? ?? 'fields',
      head: ((json['head'] as List?) ?? const []).map((e) => '$e').toList(),
      dependsName: depends?['name'] as String?,
      dependsValue: depends?['value']?.toString(),
      answer: answer.isEmpty ? null : answer,
      inputs: ((json['inputs'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_input)
          .toList(),
    );
  }

  static ReserveQuestionInputEntity _input(Map<String, dynamic> json) {
    final more = json['more'] is Map<String, dynamic>
        ? json['more'] as Map<String, dynamic>
        : null;
    return ReserveQuestionInputEntity(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      label: json['label'] as String?,
      toggle: json['toggle'] as String?,
      placeholder: json['placeholder'] as String?,
      max: (json['max'] as num?)?.toInt(),
      row: json['row']?.toString(),
      value: json['value']?.toString() ?? '',
      moreValue: json['more_value']?.toString() ?? '',
      options: ((json['options'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (o) => ReserveQuestionOptionEntity(
              value: o['value']?.toString() ?? '',
              label: o['label']?.toString() ?? '',
            ),
          )
          .toList(),
      moreLabel: more?['label'] as String?,
      moreMin: (more?['min'] as num?)?.toInt(),
    );
  }
}
