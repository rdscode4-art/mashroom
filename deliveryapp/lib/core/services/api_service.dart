import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  static String? token;
  static final Dio _dio = _init();

  static Dio _init() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    return dio;
  }

  static void _setAuth() {
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token != null && token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        debugPrint('❌ API Error: ${e.response?.statusCode} ${e.requestOptions.path}');
        return handler.next(e);
      },
    ));
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(AppConstants.tokenKey);
    _setAuth();
  }

  static Future<void> saveToken(String t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, t);
    token = t;
    _setAuth();
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    token = null;
    _setAuth();
  }

  // ── AUTH ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final r = await _dio.post('/auth/send-otp', data: {'phone': phone});
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final r = await _dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
    final data = r.data as Map<String, dynamic>;
    if (data['success'] == true && data['token'] != null) {
      await saveToken(data['token'] as String);
    }
    return data;
  }

  // ── DELIVERY PARTNER ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> registerPartner({
    required String name,
    required String phone,
    required String vehicleType,
    String vehicleNumber = '',
  }) async {
    _setAuth();
    final r = await _dio.post('/delivery/register', data: {
      'name': name, 'phone': phone,
      'vehicleType': vehicleType, 'vehicleNumber': vehicleNumber,
    });
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> submitKyc({
    required String aadharNumber,
    required String dlNumber,
    required String aadharFrontPath,
    required String aadharBackPath,
    required String dlImagePath,
  }) async {
    _setAuth();
    final formData = FormData.fromMap({
      'aadharNumber': aadharNumber,
      'dlNumber': dlNumber,
      'aadharFront': await MultipartFile.fromFile(aadharFrontPath, filename: aadharFrontPath.split('/').last),
      'aadharBack': await MultipartFile.fromFile(aadharBackPath, filename: aadharBackPath.split('/').last),
      'dlImage': await MultipartFile.fromFile(dlImagePath, filename: dlImagePath.split('/').last),
    });
    final r = await _dio.post('/delivery/kyc', data: formData);
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    _setAuth();
    final r = await _dio.get('/delivery/profile');
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    _setAuth();
    final r = await _dio.get('/delivery/dashboard');
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String vehicleType,
    required String vehicleNumber,
    String? profileImagePath,
  }) async {
    _setAuth();
    final data = <String, dynamic>{
      'name': name,
      'email': email,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
    };

    dynamic payload = data;
    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      payload = FormData.fromMap({
        ...data,
        'profileImage': await MultipartFile.fromFile(
          profileImagePath,
          filename: profileImagePath.split('/').last,
        ),
      });
    }

    final r = await _dio.put('/delivery/profile', data: payload);
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> toggleOnline() async {
    _setAuth();
    final r = await _dio.put('/delivery/toggle-online');
    return r.data as Map<String, dynamic>;
  }

  static Future<void> updateLocation(double lat, double lng) async {
    _setAuth();
    await _dio.put('/delivery/location', data: {'latitude': lat, 'longitude': lng});
  }

  static Future<Map<String, dynamic>> getAssignedOrder() async {
    _setAuth();
    final r = await _dio.get('/delivery/order/assigned');
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOrderHistory() async {
    _setAuth();
    final r = await _dio.get('/delivery/orders/history');
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    _setAuth();
    try {
      final r = await _dio.put('/delivery/order/$orderId/accept');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return e.response?.data as Map<String, dynamic>? ??
          {'success': false, 'message': 'Failed to accept order'};
    }
  }

  static Future<Map<String, dynamic>> confirmPickup(String orderId, String otp) async {
    _setAuth();
    try {
      final r = await _dio.put('/delivery/order/$orderId/pickup', data: {'otp': otp});
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to confirm pickup');
    }
  }

  static Future<Map<String, dynamic>> markDelivered(String orderId, String otp) async {
    _setAuth();
    try {
      final r = await _dio.put('/delivery/order/$orderId/deliver', data: {'otp': otp});
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to mark delivered');
    }
  }

  // ── WALLET & WITHDRAWALS ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getWalletHistory() async {
    _setAuth();
    final r = await _dio.get('/delivery/wallet/history');
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String method,
    String? upiId,
    Map<String, dynamic>? bankDetails,
  }) async {
    _setAuth();
    final r = await _dio.post('/delivery/wallet/withdraw', data: {
      'amount': amount,
      'method': method,
      if (upiId != null) 'upiId': upiId,
      if (bankDetails != null) 'bankDetails': bankDetails,
    });
    return r.data as Map<String, dynamic>;
  }

  // ── SUPPORT TICKETS ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> submitSupportTicket({
    required String subject,
    required String message,
  }) async {
    _setAuth();
    final r = await _dio.post('/auth/tickets', data: {
      'subject': subject,
      'message': message,
    });
    return r.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getSupportTickets() async {
    _setAuth();
    final r = await _dio.get('/auth/tickets');
    if (r.data['success'] == true) {
      return r.data['tickets'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchSettings() async {
    final r = await _dio.get('/settings');
    return r.data as Map<String, dynamic>;
  }
}
