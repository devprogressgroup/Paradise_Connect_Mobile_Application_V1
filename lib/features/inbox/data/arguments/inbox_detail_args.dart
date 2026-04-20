import 'package:flutter/material.dart';
import '../../domain/entities/inbox_contact_entity.dart';

class InboxDetailArgs {
  final InboxContact data;
  final IconData icon;

  InboxDetailArgs({
    required this.data,
    required this.icon,
  });
}