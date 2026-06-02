import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:organic_grow/routing/route_constant.dart';

import 'package:organic_grow/core/controllers/profile_controller.dart';

class RegisterController extends GetxController {
  var isLoading = false.obs;
  
  // Prefilled phone number passed from OTP verification arguments
  late String phone;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  var selectedRole = 'customer'.obs; // Default role as customer

  @override
  void onInit() {
    super.onInit();
    // Prefill phone from arguments (defaults to empty string if not passed)
    phone = Get.arguments as String? ?? '';
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  void _showSnackbar(String title, String message, {bool isError = true}) {
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
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Triggers API request to register the new user profile details
  Future<void> submitRegistration() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final address = addressController.text.trim();
    final city = cityController.text.trim();
    final stateStr = stateController.text.trim();
    final pincode = pincodeController.text.trim();

    // Validation checks
    if (name.isEmpty || email.isEmpty || address.isEmpty || city.isEmpty || stateStr.isEmpty || pincode.isEmpty) {
      _showSnackbar('Missing Fields', 'Please fill in all details to complete registration.');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      _showSnackbar('Invalid Email', 'Please enter a valid email address.');
      return;
    }

    if (pincode.length != 6) {
      _showSnackbar('Invalid Pincode', 'Pincode must be a 6-digit numeric code.');
      return;
    }

    try {
      isLoading.value = true;
      final response = await ApiService.registerUser(
        name: name,
        email: email,
        phone: phone,
        role: selectedRole.value,
        fullAddress: address,
        city: city,
        state: stateStr,
        pincode: pincode,
        latitude: 0.0,
        longitude: 0.0,
      );

      if (response['success'] == true) {
        _showSnackbar('Registration Complete', 'Welcome aboard to Organic Grow!', isError: false);
        
        // Instantly refresh the global profile controller state with the newly verified session
        try {
          if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().fetchUserProfile();
          } else {
            Get.put(ProfileController()).fetchUserProfile();
          }
        } catch (_) {}
        
        // Successful signup maps token, then routes straight to Main dashboard
        Get.offAllNamed(RouteConstant.dashBoardPae);
      }
    } catch (e) {
      _showSnackbar('Registration Failed', e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }
}
