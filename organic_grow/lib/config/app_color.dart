
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppColor {
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF8BC34A);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  
  static Color get textColor {
    try {
      if (Get.context != null) {
        return Theme.of(Get.context!).colorScheme.onSurface;
      }
    } catch (_) {}
    return const Color(0xFF1E272C);
  }
  
  static const Color btnColor = Color(0xFFFFC107);

  static Color get greyColor => Get.isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

  static Color get lightGreyColor => Get.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
}

