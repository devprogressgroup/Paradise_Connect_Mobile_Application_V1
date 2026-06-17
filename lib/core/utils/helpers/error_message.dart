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
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String? message;

    if (data is Map<String, dynamic>) {
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        message = data['message'].toString();
      } else if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final firstError = errors.values.first;
        message = (firstError is List && firstError.isNotEmpty)
            ? firstError.first.toString()
            : firstError.toString();
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    message ??= e.message ?? defaultMessage;

    return statusCode != null ? '[$statusCode] $message' : message;
  } catch (_) {
    return defaultMessage;
  }
}