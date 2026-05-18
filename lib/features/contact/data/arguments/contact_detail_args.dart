import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';

class ContactDetailArgs {
  final ContactAttachment? dataAttachment;
  final ContactEntity? dataContact;
  final ActivityEntity? dataActivity;
  final int page;
  final String? namePage;
  final int initialTab;
  final String? sourceRoute;
  final String? focusField;

  ContactDetailArgs({
    this.dataAttachment,
    this.dataContact,
    this.dataActivity,
    this.page = 0, // 0: create 1: edit
    this.namePage,
    this.initialTab = 0,
    this.sourceRoute,
    this.focusField,
  });

  ContactDetailArgs copyWith({
    ContactAttachment? dataAttachment,
    ContactEntity? dataContact,
    ActivityEntity? dataActivity,
    int? page,
    String? namePage,
    int? initialTab,
    String? sourceRoute,
    String? focusField,
  }) {
    return ContactDetailArgs(
      dataAttachment: dataAttachment ?? this.dataAttachment,
      dataContact: dataContact ?? this.dataContact,
      dataActivity: dataActivity ?? this.dataActivity,
      page: page ?? this.page,
      namePage: namePage ?? this.namePage,
      initialTab: initialTab ?? this.initialTab,
      sourceRoute: sourceRoute ?? this.sourceRoute,
      focusField: focusField ?? this.focusField,
    );
  }
}
