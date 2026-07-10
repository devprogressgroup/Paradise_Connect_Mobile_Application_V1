import 'package:progress_group/features/attandance/domain/entities/attendance_feedback_entity.dart';

class AttendanceFeedbackModel extends AttendanceFeedbackEntity {
  AttendanceFeedbackModel({
    super.verdict,
    super.verdictLabel,
    super.categories,
    super.note,
    super.status,
    super.feedbackDatetime,
  });

  factory AttendanceFeedbackModel.fromJson(Map<String, dynamic> json) {
    return AttendanceFeedbackModel(
      verdict: json['verdict'],
      verdictLabel: json['verdict_label'],
      categories: json['categories'] != null ? List<String>.from(json['categories']) : [],
      note: json['note'],
      status: json['status'],
      feedbackDatetime: json['feedback_datetime'],
    );
  }
}
