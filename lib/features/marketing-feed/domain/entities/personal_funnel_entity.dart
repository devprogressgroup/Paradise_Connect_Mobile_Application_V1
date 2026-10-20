import 'package:equatable/equatable.dart';

class FunnelStageEntity extends Equatable {
  final String label;
  final int count;

  const FunnelStageEntity({required this.label, required this.count});

  @override
  List<Object?> get props => [label, count];
}

/// Funnel pribadi sales di kartu "Progress Kamu" (Leads → Appt → Visit → Reserve → SP).
class PersonalFunnelEntity extends Equatable {
  final String periodLabel;
  final List<FunnelStageEntity> stages;

  const PersonalFunnelEntity({required this.periodLabel, required this.stages});

  int get maxCount => stages.fold(0, (max, s) => s.count > max ? s.count : max);

  @override
  List<Object?> get props => [periodLabel, stages];
}
