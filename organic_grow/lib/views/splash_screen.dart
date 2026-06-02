import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:organic_grow/core/controllers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});

  final SplashController splashController = Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    print("we are in the splash screen");
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: GetBuilder<SplashController>(
          builder: (controller) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo with fade and scale effects
                AnimatedBuilder(
                  animation: controller.animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: controller.fadeAnimation.value,
                      child: Transform.scale(
                        scale: controller.scaleAnimation.value,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/images/logo.png',
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // App name with fade animation
                FadeTransition(
                  opacity: controller.fadeAnimation,
                  child: const Text(
                    'RiFresh INDIA',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Tagline with delayed fade animation
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: controller.animationController,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                    ),
                  ),
                  child: const Text(
                    'Fresh Organic Products',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Loading animation (appears after main animation)
                if (controller.isAnimationCompleted)
                  Lottie.asset(
                    'assets/banner_images/banner2.png', // Add a loading animation
                    width: 100,
                    height: 100,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
