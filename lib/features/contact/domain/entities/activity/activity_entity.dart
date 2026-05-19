import 'package:equatable/equatable.dart';

class ActivityEntity extends Equatable {
  final int activityId;
  final int contactId;
  final int? dealId;
  final String activityType;
  final String activityDate;
  final String? notes;
  final String? nextFollowUpDate;
  final int createdBy;
  final String createdAt;
  final String? imagePath;
  final List<String>? imagePaths;
  final String? phoneNumber;
  final String? whatsappNumber;
  final int? waId;
  final String? contactName;
  final String? jid;
  final bool? isGroup;
  final String? initials;
  final String? sessionCode;
  final int? statusFollow;

  const ActivityEntity({
    required this.activityId,
    required this.contactId,
    this.dealId,
    required this.activityType,
    required this.activityDate,
    this.notes,
    this.nextFollowUpDate,
    required this.createdBy,
    required this.createdAt,
    this.imagePath,
    this.imagePaths,
    this.phoneNumber,
    this.whatsappNumber,
    this.waId,
    this.contactName,
    this.jid,
    this.isGroup,
    this.initials,
    this.sessionCode,
    this.statusFollow,
  });

  @override
  List<Object?> get props => [
        activityId,
        contactId,
        dealId,
        activityType,
        activityDate,
        notes,
        nextFollowUpDate,
        createdBy,
        createdAt,
        imagePath,
        imagePaths,
        phoneNumber,
        whatsappNumber,
        waId,
        contactName,
        jid,
        isGroup,
        initials,
        sessionCode,
        statusFollow,
      ];
}
