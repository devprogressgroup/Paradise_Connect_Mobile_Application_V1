import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';

class MarketingFeedException implements Exception {
  final String message;
  final String? errorCode;
  final Map<String, dynamic>? errors;
  final String? raptor;
  final String? hint;
  final String? traceId;
  final int? statusCode;

  const MarketingFeedException({
    required this.message,
    this.errorCode,
    this.errors,
    this.raptor,
    this.hint,
    this.traceId,
    this.statusCode,
  });

  bool get isStorageError => errorCode == 'STORAGE_ERROR' || raptor != null;
  bool get isNotFound => errorCode == 'NOT_FOUND' || statusCode == 404;
  bool get isBusinessRule => errorCode == 'BUSINESS_RULE';
  bool get isValidation => errorCode == 'VALIDATION';

  @override
  String toString() {
    if (raptor != null && raptor!.isNotEmpty) {
      return '$message\n$raptor';
    }
    return message;
  }
}

MarketingFeedException parseMarketingFeedException(dynamic error, [String fallback = 'Terjadi kesalahan. Silakan coba lagi.']) {
  if (error is MarketingFeedException) return error;

  // Body `{status: false, ...}` yang lolos dengan HTTP 2xx.
  if (error is Map) {
    return _fromBody(Map<String, dynamic>.from(error), null, fallback);
  }

  if (error is DioException) {
    final res = error.response;
    final statusCode = res?.statusCode;
    final data = res?.data;

    if (data is Map) {
      return _fromBody(Map<String, dynamic>.from(data), statusCode, fallback);
    }

    return MarketingFeedException(
      message: getErrorMessage(error, fallback),
      statusCode: statusCode,
    );
  }

  if (error == null) return MarketingFeedException(message: fallback);
  return MarketingFeedException(message: error.toString());
}

MarketingFeedException _fromBody(Map<String, dynamic> map, int? statusCode, String fallback) {
  final errorCode = map['error_code']?.toString();
  var message = map['message']?.toString();
  final errors = map['errors'] is Map ? Map<String, dynamic>.from(map['errors'] as Map) : null;
  String? raptor;
  String? hint;

  if (map['data'] is Map) {
    final dMap = Map<String, dynamic>.from(map['data'] as Map);
    raptor = dMap['raptor']?.toString();
    hint = dMap['hint']?.toString();
  }

  final traceId = map['trace_id']?.toString();

  // VALIDATION: tampilkan pesan field pertama.
  if (errors != null && errors.isNotEmpty) {
    final firstVal = errors.values.first;
    if (firstVal is List && firstVal.isNotEmpty) {
      message = firstVal.first.toString();
    } else if (firstVal is String && firstVal.isNotEmpty) {
      message = firstVal;
    }
  }

  if (statusCode == 404 && (message == null || message.isEmpty)) {
    message = 'Post tidak ditemukan.';
  }

  message ??= fallback;
  if (traceId != null && traceId.isNotEmpty && (statusCode == 500 || errorCode == 'SERVER_ERROR')) {
    message = '$message (Trace ID: $traceId)';
  }

  return MarketingFeedException(
    message: message,
    errorCode: errorCode ?? (statusCode == 404 ? 'NOT_FOUND' : null),
    errors: errors,
    raptor: raptor,
    hint: hint,
    traceId: traceId,
    statusCode: statusCode,
  );
}
