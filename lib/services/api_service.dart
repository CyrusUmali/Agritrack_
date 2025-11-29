// lib/core/services/api_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final Dio _dio;
  Timer? _wakeUpTimer;
  DateTime? _firstWakeUpTime;

  // Servers to wake up
  static const List<String> wakeUpServers = [
    'https://agritrack-server.onrender.com',
    'https://aicrop.onrender.com',
  ];

  static const Duration _wakeUpInterval = Duration(minutes: 10);
  static const Duration _maxWakeUpDuration = Duration(hours: 3);

  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = 'https://agritrack-server.onrender.com';
    // _dio.options.baseUrl = 'http://localhost:3001';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // Wake all servers (only once per session) and start periodic wakeups
  Future<void> wakeUpServer() async {
    if (_firstWakeUpTime == null) {
      _firstWakeUpTime = DateTime.now();
      _startPeriodicWakeUps();
    }

    await _wakeAllServers();
  }

  // Ping all servers once
  Future<void> _wakeAllServers() async {
    for (final server in wakeUpServers) {
      await _pingServer(server);
    }
  }

  // Ping one server with retry logic
  Future<void> _pingServer(String url) async {
    const int maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _dio
            .get('$url/wakeup')
            .timeout(const Duration(seconds: 5));
        return;
      } catch (e) {
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  void _startPeriodicWakeUps() {
    _wakeAllServers();

    _wakeUpTimer = Timer.periodic(_wakeUpInterval, (timer) {
      if (_firstWakeUpTime != null &&
          DateTime.now().difference(_firstWakeUpTime!) >=
              _maxWakeUpDuration) {
        _stopPeriodicWakeUps();
        return;
      }

      _wakeAllServers();
    });
  }

  void _stopPeriodicWakeUps() {
    _wakeUpTimer?.cancel();
    _wakeUpTimer = null;
    _firstWakeUpTime = null;
  }

  void stopWakeUpCalls() {
    _stopPeriodicWakeUps();
  }

  void dispose() {
    _stopPeriodicWakeUps();
    _dio.close();
  }

  Future<Response> get(String path,
          {Map<String, dynamic>? queryParameters}) async =>
      await _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) async =>
      await _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) async =>
      await _dio.put(path, data: data);

  Future<Response> delete(String path) async => await _dio.delete(path);
}
