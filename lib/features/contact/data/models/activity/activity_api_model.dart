import '../../../domain/entities/activity/activity_entity.dart';

class ActivityApiModel extends ActivityEntity {

   ActivityApiModel({
    required super.activityId,
    required super.contactId,
    super.dealId,
    required super.activityType,
    required super.activityDate,
    super.notes,
    super.nextFollowUpDate,
    required super.createdBy,
    required super.createdAt,
    super.imagePath,
    super.imagePaths,
    super.phoneNumber,
    super.whatsappNumber,
    super.waId,
    super.contactName,
    super.jid,
    super.isGroup,
    super.initials,
    super.sessionCode,
    super.statusFollow,
  });

  factory ActivityApiModel.fromJson(Map<String, dynamic> json) {
    return ActivityApiModel(
      activityId: json['activity_id'],
      contactId: json['contact_id'],
      dealId: json['deal_id'],
      activityType: json['activity_type'] ?? '',
      activityDate: json['activity_date'] ?? '',
      notes: json['notes'],
      nextFollowUpDate: json['next_follow_up_date'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] ?? '',
      imagePath: json['image_path'],
      imagePaths: json['image_paths'] != null ? List<String>.from(json['image_paths']) : null,
      phoneNumber: json['phone_number'],
      whatsappNumber: json['whatsapp_number'],
      waId: json['id'],
      contactName: json['contact_name'],
      jid: json['jid'],
      isGroup: json['isGroup'],
      initials: json['initials'],
      sessionCode: json['sessionCode'],
      statusFollow: json['status_follow'],
    );
  }
}

class ActivityResponseModel {
  final List<ActivityApiModel> activities;
  final int currentPage;
  final bool hasReachedMax;

  ActivityResponseModel({
    required this.activities,
    required this.currentPage,
    required this.hasReachedMax,
  });

  factory ActivityResponseModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    return ActivityResponseModel(
      activities: data.map((e) => ActivityApiModel.fromJson(e)).toList(),
      currentPage: json['current_page'] ?? 1,
      hasReachedMax: json['next_page_url'] == null,
    );
  }
}
