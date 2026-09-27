import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central HTTP client both apps use to talk to the NestJS backend.
/// Automatically attaches the current Firebase ID token to every request.
class ApiClient {
  final Dio dio;

  ApiClient({required String baseUrl})
      : dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10))) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) =>
      dio.get(path, queryParameters: query);

  Future<Response> post(String path, {Object? data}) => dio.post(path, data: data);
}

/// Point this at your deployed backend, or http://10.0.2.2:3000 for the
/// Android emulator talking to a backend running on your dev machine.
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
