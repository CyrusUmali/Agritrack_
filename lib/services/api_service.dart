// lib/core/services/api_service.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final Dio _dio;
  Timer? _wakeUpTimer;
  DateTime? _firstWakeUpTime;
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

  // Ping the server to wake it up (retry if needed) and schedule periodic wake-ups
  Future<void> wakeUpServer() async {
    // If this is the first wake-up call, start the periodic timer
    if (_firstWakeUpTime == null) {
      _firstWakeUpTime = DateTime.now();
      _startPeriodicWakeUps();
    }

    await _performWakeUpCall();
  }

  // Perform a single wake-up call with retries
  Future<void> _performWakeUpCall() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _dio.get('/wakeup').timeout(const Duration(seconds: 5));
        // print("Server wake-up successful (attempt $attempt)");
        return; // Success, server is awake
      } catch (e) {
        // print("Server wake-up attempt $attempt failed: $e");
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
    // print("Warning: Server wake-up failed after $maxRetries attempts");
  }

  // Start periodic wake-up calls every 10 minutes for 3 hours
  void _startPeriodicWakeUps() {
    // print(
    //     "Starting periodic server wake-up calls every 10 minutes for 3 hours");

    // Immediate first call (already done in wakeUpServer, but we'll do it here too for safety)
    _performWakeUpCall();

    // Set up periodic timer
    _wakeUpTimer = Timer.periodic(_wakeUpInterval, (timer) {
      // Check if we've exceeded the 3-hour limit
      if (_firstWakeUpTime != null &&
          DateTime.now().difference(_firstWakeUpTime!) >= _maxWakeUpDuration) {
        _stopPeriodicWakeUps();
        // print("Stopped periodic server wake-up calls after 3 hours");
        return;
      }

      _performWakeUpCall();
    });
  }

  // Stop the periodic wake-up calls
  void _stopPeriodicWakeUps() {
    _wakeUpTimer?.cancel();
    _wakeUpTimer = null;
    _firstWakeUpTime = null;
  }

  // Public method to manually stop wake-up calls if needed
  void stopWakeUpCalls() {
    _stopPeriodicWakeUps();
    // print("Manual stop: Server wake-up calls cancelled");
  }

  // Clean up when the service is no longer needed
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
