import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../../services/push_notification_service.dart';
import '../models/partner_model.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var partner = Rxn<DeliveryPartner>();
  var isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await ApiService.loadToken();
    if (ApiService.token != null && ApiService.token!.isNotEmpty) {
      try {
        final res = await ApiService.getProfile();
        if (res['success'] == true && res['partner'] != null) {
          partner.value = DeliveryPartner.fromJson(res['partner'] as Map<String, dynamic>);
          isLoggedIn.value = true;
          if (partner.value!.isApproved) {
            Get.offAllNamed('/home');
          } else {
            Get.offAllNamed('/register-partner', arguments: partner.value);
          }
        } else {
          // Logged in but no partner profile yet
          isLoggedIn.value = true;
          Get.offAllNamed('/register-partner');
        }
      } catch (_) {
        isLoggedIn.value = false;
      }
    }
  }

  Future<void> sendOtp(String phone) async {
    isLoading.value = true;
    try {
      final res = await ApiService.sendOtp(phone);
      if (res['success'] == true) {
        Get.snackbar('OTP Sent', 'Use OTP: ${res['otp']}',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      } else {
        throw Exception(res['message']);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.redAccent, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    isLoading.value = true;
    try {
      final res = await ApiService.verifyOtp(phone, otp);
      if (res['success'] == true) {
        isLoggedIn.value = true;
        // Sync FCM token since user is now logged in
        PushNotificationService.syncToken();
        // Check if partner profile exists
        try {
          final profileRes = await ApiService.getProfile();
          if (profileRes['success'] == true && profileRes['partner'] != null) {
            partner.value = DeliveryPartner.fromJson(profileRes['partner'] as Map<String, dynamic>);
            if (partner.value!.isApproved) {
              Get.offAllNamed('/home');
            } else {
              Get.offAllNamed('/register-partner', arguments: partner.value);
            }
          } else {
            Get.offAllNamed('/register-partner');
          }
        } catch (_) {
          Get.offAllNamed('/register-partner');
        }
      } else {
        throw Exception(res['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.redAccent, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    partner.value = null;
    isLoggedIn.value = false;
    Get.offAllNamed('/login');
  }

  Future<void> refreshProfile() async {
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true && res['partner'] != null) {
        partner.value = DeliveryPartner.fromJson(res['partner'] as Map<String, dynamic>);
      }
    } catch (_) {}
  }
}
