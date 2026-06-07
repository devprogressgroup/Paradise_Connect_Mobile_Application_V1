import 'package:dio/dio.dart';

/// Strips the "Exception: " prefix that Dart adds when calling .toString()
/// on a plain Exception object, so SnackBars show a clean message.
String cleanErrorMessage(Object e) {
  final raw = e.toString();
  if (raw.startsWith('Exception: ')) return raw.substring(11);
  return raw.replaceAll('  ', '').trim();
}

String getErrorMessage(DioException e, String defaultMessage) {
    try {
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          return data['message'].toString();
        }

        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;

          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }

          return firstError.toString();
        }
      }

      if (data is String && data.isNotEmpty) {
        return data;
      }

      return e.message ?? defaultMessage;
    } catch (_) {
      return defaultMessage;
    }
  }