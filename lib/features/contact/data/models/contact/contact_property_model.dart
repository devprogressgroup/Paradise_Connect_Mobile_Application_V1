import '../../../domain/entities/contact/contact_property.dart';

class ContactPropertyModel extends ContactProperty {
  ContactPropertyModel({
    required super.propertyId,
    super.objectId,
    required super.groupId,
    required super.name,
    required super.label,
    required super.fieldType,
    super.options = const [],
    super.sourceTable,
    super.sourceValueKey,
    super.sourceLabelKey,
  });

  factory ContactPropertyModel.fromJson(Map<String, dynamic> json) {
    return ContactPropertyModel(
      propertyId: json['property_id'],
      objectId: json['object_id'],
      groupId: json['group_id'],
      name: json['name'],
      label: json['label'],
      fieldType: json['field_type'],
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => {
                    'label': o['label']?.toString() ?? '',
                    'value': o['value']?.toString() ?? '',
                  })
              .toList() ??
          [],
      sourceTable: json['source_table'] as String?,
      sourceValueKey: json['source_value_key'] as String?,
      sourceLabelKey: json['source_label_key'] as String?,
    );
  }
}

class ContactPropertyGroupModel extends ContactPropertyGroup {
  ContactPropertyGroupModel({
    required super.id,
    required super.name,
    required super.label,
    super.properties = const [],
  });

  factory ContactPropertyGroupModel.fromJson(Map<String, dynamic> json) {
    final props = (json['contact_properties'] as List<dynamic>?) ?? [];
    return ContactPropertyGroupModel(
      id: json['id'],
      name: json['name'],
      label: json['label'],
      properties: props.map((p) => ContactPropertyModel.fromJson(p)).toList(),
    );
  }
}
