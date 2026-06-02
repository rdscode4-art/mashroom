import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Sleek organic ambient glow background
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.primaryColor.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.secondaryColor.withOpacity(0.04),
              ),
            ),
          ),

          // 2. Main content container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Brand Logo - Contain fit to keep original logo proportions
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 16),

                    // App Title
                    Center(
                      child: Text(
                        'RiFresh INDIA',
                        style: AppTypography.h1.copyWith(
                          color: AppColor.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 8),

                    // Tagline
                    Center(
                      child: Text(
                        'Pure & pesticide-free local farm produce',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColor.textColor.withOpacity(0.5),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 40),

                    // Input Card Wrapper
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ]
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Enter Phone Number',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColor.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Styled Phone Text Field
                          TextField(
                            controller: authController.phoneController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 10,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '+91',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primaryColor,
                                  ),
                                ),
                              ),
                              hintText: '98765 43210',
                              hintStyle: AppTypography.bodyLarge.copyWith(
                                color: AppColor.textColor.withOpacity(0.3),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColor.primaryColor, width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.length > 10) {
                                authController.phoneController.text = value.substring(0, 10);
                                authController.phoneController.selection =
                                    TextSelection.fromPosition(const TextPosition(offset: 10));
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // OTP and Verification actions nested inside the card for perfect alignment and width
                          Obx(() {
                            final isSent = authController.otpSent.value;
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: isSent
                                  ? Column(
                                      key: const ValueKey('otp_section'),
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Enter 4-Digit OTP',
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColor.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        
                                        // Pinput OTP Input Field (4 Digits)
                                        Center(
                                          child: Pinput(
                                            length: 4,
                                            controller: authController.otpController,
                                            keyboardType: TextInputType.number,
                                            autofocus: true,
                                            onCompleted: (pin) {
                                              authController.verifyOtp();
                                            },
                                            defaultPinTheme: PinTheme(
                                              width: 56,
                                              height: 56,
                                              textStyle: AppTypography.h3.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColor.textColor,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Theme.of(context).dividerColor),
                                                color: AppColor.primaryColor.withOpacity(0.02),
                                              ),
                                            ),
                                            focusedPinTheme: PinTheme(
                                              width: 56,
                                              height: 56,
                                              textStyle: AppTypography.h3.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColor.textColor,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AppColor.primaryColor, width: 2),
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColor.primaryColor.withOpacity(0.08),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  )
                                                ]
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  final phone = authController.phoneController.text;
                                                  if (authController.isValidPhone(phone)) {
                                                    authController.sendOtp();
                                                  } else {
                                                    Get.snackbar(
                                                      'Error',
                                                      'Enter a valid 10-digit mobile number starting with 6-9',
                                                    );
                                                  }
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Resend',
                                                  style: AppTypography.buttonMedium.copyWith(
                                                    color: AppColor.textColor.withOpacity(0.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: authController.verifyOtp,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColor.primaryColor,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Verify OTP',
                                                  style: AppTypography.buttonMedium.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        key: const ValueKey('send_otp_button'),
                                        onPressed: () {
                                          final phone = authController.phoneController.text;
                                          if (authController.isValidPhone(phone)) {
                                            authController.sendOtp();
                                          } else {
                                            Get.snackbar(
                                              'Error',
                                              'Enter a valid 10-digit mobile number starting with 6-9',
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColor.primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                          shadowColor: AppColor.primaryColor.withOpacity(0.2),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          'Send OTP',
                                          style: AppTypography.buttonLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                            );
                          }),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // 3. Absolute Glassmorphic Loader Overlay
          Obx(() {
            if (authController.isLoading.value) {
              return Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                        )
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColor.primaryColor),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Verifying...',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColor.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }
}
