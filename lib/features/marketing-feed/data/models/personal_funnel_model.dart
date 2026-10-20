import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';

class PersonalFunnelModel extends PersonalFunnelEntity {
  const PersonalFunnelModel({required super.periodLabel, required super.stages});

  factory PersonalFunnelModel.fromJson(Map<String, dynamic> json) {
    return PersonalFunnelModel(
      periodLabel: json['period_label'] as String? ?? '',
      stages: (json['stages'] as List<dynamic>? ?? const [])
          .map((e) => FunnelStageEntity(
                label: e['label'] as String? ?? '',
                count: (e['count'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
    );
  }
}
