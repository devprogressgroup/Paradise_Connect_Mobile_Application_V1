import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.com/api'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    print('path: ${options.path}');
    handler.reject(DioException(requestOptions: options));
  }));
  
  try {
    await dio.post('/ocr/ktp');
  } catch (e) {}
  
  try {
    await dio.post('ocr/ktp');
  } catch (e) {}
}
