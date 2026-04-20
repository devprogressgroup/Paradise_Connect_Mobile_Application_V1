import '../../domain/entities/inbox_contact_entity.dart';

abstract class InboxContactState {}

class InboxContactInitial extends InboxContactState {}

class InboxContactLoading extends InboxContactState {}

class InboxContactLoaded extends InboxContactState {
  final List<InboxContact> contacts;
  final List<InboxContact> groups;

  InboxContactLoaded(this.contacts, this.groups);
}

class InboxContactError extends InboxContactState {
  final String message;

  InboxContactError(this.message);
}