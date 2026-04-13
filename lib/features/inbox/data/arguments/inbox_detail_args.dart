import 'package:flutter/material.dart';
import 'package:progress_group/features/inbox/data/models/dropdown_model.dart';

class InboxDetailArgs {
  final DropdownItemModel data;
  final IconData icon;

  InboxDetailArgs({
    required this.data,
    required this.icon,
  });
}