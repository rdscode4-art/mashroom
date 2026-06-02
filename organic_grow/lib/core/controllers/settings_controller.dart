import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  var isDarkMode = false.obs;
  var isNotificationEnabled = true.obs;
  var isLocationEnabled = true.obs;

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleNotification(bool value) {
    isNotificationEnabled.value = value;
  }

  void toggleLocation(bool value) {
    isLocationEnabled.value = value;
  }
}