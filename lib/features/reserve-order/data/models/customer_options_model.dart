import 'package:progress_group/features/reserve-order/domain/entities/customer_options_entity.dart';

class CustomerOptionsModel extends CustomerOptionsEntity {
  const CustomerOptionsModel({
    required super.fields,
    required super.lists,
    required super.other,
  });

  /// `{fields: {kolom: nama daftar}, options: {nama daftar: [{value, label}]}, other: "Lainnya"}`.
  factory CustomerOptionsModel.fromJson(Map<String, dynamic> json) {
    final fields = (json['fields'] as Map? ?? const {}).map(
      (key, list) => MapEntry('$key', '$list'),
    );
    final lists = (json['options'] as Map? ?? const {}).map(
      (name, items) => MapEntry('$name', [
        for (final item in (items as List? ?? const []))
          CustomerOptionEntity(
            value: '${item['value']}',
            label: '${item['label']}'.trim(),
          ),
      ]),
    );
    return CustomerOptionsModel(
      fields: fields,
      lists: lists,
      other: json['other']?.toString() ?? '',
    );
  }
}
