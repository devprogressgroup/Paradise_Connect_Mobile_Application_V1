class AttendanceFeedbackEntity {
  final int? verdict;
  final String? verdictLabel;
  final List<String> categories;
  final String? note;
  final String? status;
  final String? feedbackDatetime;

  AttendanceFeedbackEntity({
    this.verdict,
    this.verdictLabel,
    this.categories = const [],
    this.note,
    this.status,
    this.feedbackDatetime,
  });

  bool get isOk => verdict == 1;
}
