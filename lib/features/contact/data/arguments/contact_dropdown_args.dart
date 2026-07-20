import 'package:progress_group/features/attandance/domain/entities/location_entity.dart';

class OwnerDropdownItem {
  final int? id;
  final String name;
  final AttendanceLocation? attendanceLocation;
  final String? typeData;
  final String? subtitle;

  OwnerDropdownItem({this.id, required this.name, this.attendanceLocation, this.typeData, this.subtitle});
}

class ContactDropdownArgs {
  final String title;
  final List<OwnerDropdownItem> items;
  final int? selectedId;
  final String? selectedName;
  final List<int>? selectedIds;
  final bool isMultiSelect;
  final bool allowClear;
  final bool preserveOrder;

  ContactDropdownArgs({
    required this.title,
    required this.items,
    this.selectedId,
    this.selectedName,
    this.selectedIds,
    this.isMultiSelect = false,
    this.allowClear = false,
    this.preserveOrder = false,
  });
}