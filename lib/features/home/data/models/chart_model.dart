class ChartModel {
  final String label;
  final double value;

  ChartModel({required this.label, required this.value});

  factory ChartModel.fromJson(Map<String, dynamic> json) {
    return ChartModel(
      label: json['label'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'label': label, 'value': value};
  }
}
