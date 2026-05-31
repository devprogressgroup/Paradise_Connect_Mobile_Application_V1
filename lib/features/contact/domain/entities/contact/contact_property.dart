class ContactProperty {
  final int propertyId;
  final int? objectId;
  final int groupId;
  final String name;
  final String label;
  final String fieldType;
  final List<Map<String, String>> options;

  ContactProperty({
    required this.propertyId,
    this.objectId,
    required this.groupId,
    required this.name,
    required this.label,
    required this.fieldType,
    this.options = const [],
  });
}

class ContactPropertyGroup {
  final int id;
  final String name;
  final String label;
  final List<ContactProperty> properties;

  ContactPropertyGroup({
    required this.id,
    required this.name,
    required this.label,
    this.properties = const [],
  });
}
