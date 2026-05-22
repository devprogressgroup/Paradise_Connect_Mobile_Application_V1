import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';

abstract class PropertyUnitState {}

class PropertyUnitInitial extends PropertyUnitState {}

class PropertyUnitLoading extends PropertyUnitState {}

class PropertyUnitLoaded extends PropertyUnitState {
  final List<OwnerDropdownItem> items;

  PropertyUnitLoaded(this.items);
}

class PropertyUnitError extends PropertyUnitState {
  final String message;

  PropertyUnitError(this.message);
}
