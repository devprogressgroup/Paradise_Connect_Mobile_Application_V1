String getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  String initials = '';
  if (parts.isNotEmpty) initials += parts[0][0].toUpperCase();
  if (parts.length > 1) initials += parts[1][0].toUpperCase();
  return initials;
}
