import 'package:progress_group/features/contact/data/models/person_model.dart';

class ContactDetailArgs {
  final PersonModel? data;
  final int page;

  ContactDetailArgs({
    this.data,
    this.page = 0, // 0: create 1: edit
  });
}