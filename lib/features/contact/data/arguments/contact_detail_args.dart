import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';
import 'package:progress_group/features/contact/domain/entities/attachment/attachment_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';
import 'package:progress_group/features/contact/domain/entities/contact/create_contact_params.dart';

class ContactDetailArgs {
  final ContactAttachment? dataAttachment;
  final ContactEntity? dataContact;
  final ActivityEntity? dataActivity;
  final CreateContactParams? createContactParams;
  final int page;
  final String? namePage;
  final int initialTab;
  final String? sourceRoute;
  final String? focusField;
  final String? buttonLabel;

  ContactDetailArgs({
    this.dataAttachment,
    this.dataContact,
    this.dataActivity,
    this.createContactParams,
    this.page = 0, // 0: create 1: edit
    this.namePage,
    this.initialTab = 0,
    this.sourceRoute,
    this.focusField,
    this.buttonLabel,
  });

  ContactDetailArgs copyWith({
    ContactAttachment? dataAttachment,
    ContactEntity? dataContact,
    ActivityEntity? dataActivity,
    CreateContactParams? createContactParams,
    int? page,
    String? namePage,
    int? initialTab,
    String? sourceRoute,
    String? focusField,
    String? buttonLabel,
  }) {
    return ContactDetailArgs(
      dataAttachment: dataAttachment ?? this.dataAttachment,
      dataContact: dataContact ?? this.dataContact,
      dataActivity: dataActivity ?? this.dataActivity,
      createContactParams: createContactParams ?? this.createContactParams,
      page: page ?? this.page,
      namePage: namePage ?? this.namePage,
      initialTab: initialTab ?? this.initialTab,
      sourceRoute: sourceRoute ?? this.sourceRoute,
      focusField: focusField ?? this.focusField,
      buttonLabel: buttonLabel ?? this.buttonLabel,
    );
  }
}
