import '../../domain/entities/report_whatsapp_entity.dart';

class ReportVolumeModel extends ReportVolume {
  ReportVolumeModel({
    required List<VolumeSeriesModel> series,
    required List<String> categories,
  }) : super(series: series, categories: categories);

  factory ReportVolumeModel.fromJson(Map<String, dynamic> json) {
    return ReportVolumeModel(
      series: (json['series'] as List) .map((i) => VolumeSeriesModel.fromJson(i)) .toList(),
      categories: List<String>.from(json['categories']),
    );
  }
}

class VolumeSeriesModel extends VolumeSeries {
  VolumeSeriesModel({required String name, required List<int> data})
      : super(name: name, data: data);

  factory VolumeSeriesModel.fromJson(Map<String, dynamic> json) {
    return VolumeSeriesModel(
      name: json['name'],
      data: List<int>.from(json['data']),
    );
  }
}