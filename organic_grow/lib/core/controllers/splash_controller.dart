import 'package:organic_grow/core/services/api_services.dart';
import '../../utils/imports.dart';

import 'package:organic_grow/core/controllers/profile_controller.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  final RxBool _isAnimationCompleted = false.obs;
  bool get isAnimationCompleted => _isAnimationCompleted.value;

  @override
  void onInit() {
    super.onInit();
    initAnimations();
    navigateToHome();
  }

  void initAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    animationController.forward();

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimationCompleted.value = true;
      }
    });
  }

  Future<void> navigateToHome() async {
    // Load local persisted token asynchronously from SharedPreferences
    await ApiService.loadToken();
    Future.delayed(const Duration(seconds: 3), () async {
      if (ApiService.userToken == null || ApiService.userToken!.isEmpty) {
        print("No token stored, navigating to Login Screen");
        Get.offAllNamed(RouteConstant.loginPage);
      } else {
        try {
          print("Token exists, verifying profile completion status...");
          final profile = await ApiService.fetchProfile();
          final user = profile['user'];
          
          // Populate the global user profile data state during app initialization
          try {
            final profileController = Get.isRegistered<ProfileController>()
                ? Get.find<ProfileController>()
                : Get.put(ProfileController());
            await profileController.fetchUserProfile();
          } catch (_) {}
          
          if (user != null && (user['name'] == null || user['name'].toString().trim().isEmpty)) {
            // Token is active but registration is incomplete -> Redirect to Register screen
            print("Profile incomplete, redirecting to Register Screen");
            final phone = user['phone'] ?? '';
            Get.offAllNamed(RouteConstant.registerPage, arguments: phone);
          } else {
            // Profile is fully complete -> Send to Dashboard
            print("Profile complete, navigating to Dashboard Screen");
            Get.offAllNamed(RouteConstant.dashBoardPae);
          }
        } catch (e) {
          // If token is invalid/expired or connection fails, clear token and route to Login
          print("Profile fetch failed, resetting token session: $e");
          await ApiService.clearToken();
          Get.offAllNamed(RouteConstant.loginPage);
        }
      }
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
