import 'package:dio/dio.dart';

class BearerInterceptor extends Interceptor {
  final String token;

  BearerInterceptor(this.token);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer $token';
    super.onRequest(options, handler);
  }
}
