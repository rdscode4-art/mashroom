import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:organic_grow/routing/route_constant.dart';
import 'package:organic_grow/services/push_notification_service.dart';

import 'package:organic_grow/core/controllers/profile_controller.dart';

class AuthController extends GetxController {
  var otpSent = false.obs;
  var isLoading = false.obs;
  
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _listenForOtp();
  }

  Future<void> _listenForOtp() async {
    try {
      await SmsAutoFill().listenForCode;
    } catch (e) {
      debugPrint("SmsAutoFill failed: $e");
    }
  }

  @override
  void onClose() {
    try {
      SmsAutoFill().unregisterListener();
    } catch (e) {
      debugPrint("SmsAutoFill unregister failed: $e");
    }
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^[6-9]\d{9}$');
    return regex.hasMatch(phone);
  }

  /// Displays standard, high-stability raw snackbars avoiding overlay tree conflicts
  void _showSnackbar(String title, String message, {bool isError = true, Duration? duration}) {
    Get.rawSnackbar(
      titleText: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: duration ?? const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Triggers API request to send OTP to the phone number
  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();
    if (!isValidPhone(phone)) {
      _showSnackbar(
        'Invalid Phone',
        'Please enter a valid 10-digit mobile number starting with 6-9',
        isError: true,
      );
      return;
    }

    try {
      isLoading.value = true;
      final response = await ApiService.sendOtp(phone);
      
      if (response['success'] == true) {
        otpSent.value = true;
        final receivedOtp = response['otp'];
        _showSnackbar(
          'OTP Sent',
          'OTP sent successfully to +91 $phone. ${receivedOtp != null ? "(Demo OTP: $receivedOtp)" : ""}',
          isError: false,
          duration: const Duration(seconds: 6),
        );
      }
    } catch (e) {
      _showSnackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifies OTP with backend, saving token and redirecting to dashboard
  Future<void> verifyOtp() async {
    final phone = phoneController.text.trim();
    final otp = otpController.text.trim();

    if (otp.length != 4) {
      _showSnackbar(
        'Invalid OTP',
        'Please enter the 4-digit OTP code.',
        isError: true,
      );
      return;
    }

    try {
      isLoading.value = true;
      final response = await ApiService.verifyOtp(phone, otp);
      
      if (response['success'] == true) {
        _showSnackbar(
          'Login Successful',
          'Welcome to Organic Grow!',
          isError: false,
        );
        
        final user = response['user'];
        if (user != null && (user['name'] == null || user['name'].toString().trim().isEmpty)) {
          // Redirect new user to registration form to complete profile details
          Get.offAllNamed(RouteConstant.registerPage, arguments: phone);
        } else {
          // Sync FCM token since user is now logged in
          PushNotificationService.syncToken();
          
          // Instantly refresh the global profile controller state with the newly verified session
          try {
            if (Get.isRegistered<ProfileController>()) {
              Get.find<ProfileController>().fetchUserProfile();
            } else {
              Get.put(ProfileController()).fetchUserProfile();
            }
          } catch (_) {}
          // Send verified existing user directly to home dashboard
          Get.offAllNamed(RouteConstant.dashBoardPae);
        }
      }
    } catch (e) {
      _showSnackbar(
        'Verification Failed',
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
