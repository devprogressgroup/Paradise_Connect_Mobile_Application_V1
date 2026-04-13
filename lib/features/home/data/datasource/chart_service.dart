import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chart_model.dart';

class ChartService {
  /// Simulates an API call by loading data from a local JSON file.
  Future<List<ChartModel>> fetchChartData() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Load JSON from assets
      final String response =
          await rootBundle.loadString('assets/data/chart_data.json');
      final data = await json.decode(response);

      // Parse JSON to List of Models
      if (data['data'] != null) {
        return (data['data'] as List)
            .map((item) => ChartModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load chart data: $e');
    }
  }
}
