import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/routing/get_pages.dart';
import 'package:organic_grow/routing/route_constant.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:organic_grow/services/push_notification_service.dart';
import 'package:organic_grow/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService.init();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  // Register CartController globally so it persists across all screens
  Get.put(CartController(), permanent: true);
  runApp(OrganicGrowApp());
}

class OrganicGrowApp extends StatelessWidget {
  const OrganicGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RiFresh INDIA',
      debugShowCheckedModeBanner: false,
      initialRoute: RouteConstant.splashPage,
      getPages: getPages,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColor.primaryColor,
        scaffoldBackgroundColor: const Color(0xFFF4F9F5),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE8F3EB),
        colorScheme: const ColorScheme.light(
          primary: AppColor.primaryColor,
          secondary: AppColor.secondaryColor,
          surface: Colors.white,
          onSurface: Color(0xFF1E272C),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColor.primaryColor,
        scaffoldBackgroundColor: const Color(0xFF0F171A),
        cardColor: const Color(0xFF162226),
        dividerColor: const Color(0xFF1E2D32),
        colorScheme: const ColorScheme.dark(
          primary: AppColor.primaryColor,
          secondary: AppColor.secondaryColor,
          surface: Color(0xFF162226),
          onSurface: Color(0xFFE8F3EB),
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.light,
    );
  }
}