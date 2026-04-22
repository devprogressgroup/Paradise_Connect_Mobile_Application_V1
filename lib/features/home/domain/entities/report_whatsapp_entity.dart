class ReportVolume {
  final List<VolumeSeries> series;
  final List<String> categories;

  ReportVolume({required this.series, required this.categories});
}

class VolumeSeries {
  final String name;
  final List<int> data;

  VolumeSeries({required this.name, required this.data});
}