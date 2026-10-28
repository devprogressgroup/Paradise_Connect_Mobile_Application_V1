import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_questionnaire_entity.dart';

class ReserveQuestionnaireModel extends ReserveQuestionnaireEntity {
  const ReserveQuestionnaireModel({super.questions, super.filledDate});

  factory ReserveQuestionnaireModel.fromJson(Map<String, dynamic> json) {
    // Daftar master utk input `select` (mis. 'location' = Wilayah Area) — dikirim sekali, input
    // menunjuknya lewat `options_ref`. `is Map` — PHP bisa kirim `[]` kalau kosong.
    final lists = <String, List<ReserveQuestionOptionEntity>>{
      if (json['option_lists'] case final Map<String, dynamic> raw)
        for (final entry in raw.entries) entry.key: _options(entry.value),
    };
    return ReserveQuestionnaireModel(
      filledDate: json['filled_date']?.toString(),
      questions: ((json['questions'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((q) => _question(q, lists))
          .toList(),
    );
  }

  static ReserveQuestionEntity _question(
    Map<String, dynamic> json,
    Map<String, List<ReserveQuestionOptionEntity>> lists,
  ) {
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
          .map((input) => _input(input, lists))
          .toList(),
    );
  }

  static ReserveQuestionInputEntity _input(
    Map<String, dynamic> json,
    Map<String, List<ReserveQuestionOptionEntity>> lists,
  ) {
    final more = json['more'] is Map<String, dynamic>
        ? json['more'] as Map<String, dynamic>
        : null;
    final ref = json['options_ref'] as String?;
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
      options: ref != null ? (lists[ref] ?? const []) : _options(json['options']),
      moreLabel: more?['label'] as String?,
      moreMin: (more?['min'] as num?)?.toInt(),
    );
  }

  static List<ReserveQuestionOptionEntity> _options(dynamic raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (o) => ReserveQuestionOptionEntity(
              value: o['value']?.toString() ?? '',
              label: o['label']?.toString().trim() ?? '',
            ),
          )
          .toList();
}
