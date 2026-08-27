import 'package:dio/dio.dart';

String cleanErrorMessage(Object e) {
  if (e is DioException) return getErrorMessage(e, 'Terjadi kesalahan. Silakan coba lagi.');
  final raw = e.toString();
  if (raw.startsWith('Exception: ')) return raw.substring(11);
  return raw.replaceAll('  ', '').trim();
}

const _kConnectionErrorMessage = 'Koneksi bermasalah. Silakan periksa jaringan Anda dan coba lagi.';

String getErrorMessage(DioException e, String defaultMessage) {
  try {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return _kConnectionErrorMessage;
      default:
        break;
    }

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

    return message;
  } catch (_) {
    return defaultMessage;
  }
}