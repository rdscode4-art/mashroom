import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/register_controller.dart';

class RegisterScreen extends StatelessWidget {
  final RegisterController registerController = Get.put(RegisterController());

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Complete Profile',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColor.primaryColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: AppColor.primaryColor.withOpacity(0.04),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: CircleAvatar(
              radius: 160,
              backgroundColor: AppColor.secondaryColor.withOpacity(0.04),
            ),
          ),

          // Main form container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Leaf Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColor.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppColor.primaryColor,
                          size: 48,
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Just one step away!',
                        style: AppTypography.h2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.primaryColor,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Please fill in your details to create your account',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColor.textColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Inputs Card Wrapper
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Name Field
                          _buildLabel('Full Name*'),
                          _buildTextField(
                            controller: registerController.nameController,
                            hint: 'Ram Kumar',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),

                          // 2. Email Field
                          _buildLabel('Email Address*'),
                          _buildTextField(
                            controller: registerController.emailController,
                            hint: 'ram.kumar@gmail.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // 3. Phone Field (Read Only)
                          _buildLabel('Phone Number'),
                          _buildTextField(
                            controller: TextEditingController(text: '+91 ${registerController.phone}'),
                            hint: '',
                            icon: Icons.phone_android_rounded,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),

                          // 4. Role Selection (Dropdown)
                          _buildLabel('Register As'),
                          Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Theme.of(context).dividerColor),
                              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: registerController.selectedRole.value,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'customer',
                                    child: Text('Customer / Buyer'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'delivery',
                                    child: Text('Delivery Partner'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    registerController.selectedRole.value = val;
                                  }
                                },
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColor.primaryColor),
                              ),
                            ),
                          )),
                          const SizedBox(height: 24),

                          // Address Section Header
                          Text(
                            'Delivery Address Details',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColor.primaryColor,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),

                          // 5. Full Address
                          _buildLabel('Street/Flat Address*'),
                          _buildTextField(
                            controller: registerController.addressController,
                            hint: '123 Green Street, Organic City',
                            icon: Icons.home_outlined,
                          ),
                          const SizedBox(height: 16),

                          // 6. City & State Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildLabel('City*'),
                                    _buildTextField(
                                      controller: registerController.cityController,
                                      hint: 'Mumbai',
                                      icon: Icons.location_city_outlined,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildLabel('State*'),
                                    _buildTextField(
                                      controller: registerController.stateController,
                                      hint: 'Maharashtra',
                                      icon: Icons.map_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 7. Pincode
                          _buildLabel('Pincode*'),
                          _buildTextField(
                            controller: registerController.pincodeController,
                            hint: '400001',
                            icon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            formatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 6,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: registerController.submitRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: AppColor.primaryColor.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Submit & Finish',
                        style: AppTypography.buttonLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Absolute Screen Loader Overlay
          Obx(() {
            if (registerController.isLoading.value) {
              return Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                        )
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColor.primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Saving details...',
                          style: TextStyle(
                            color: AppColor.textColor,
                            fontWeight: FontWeight.w600,
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

  // Label UI Builder
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColor.textColor.withOpacity(0.6),
        ),
      ),
    );
  }

  // Custom Form TextField Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLength: maxLength,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: enabled ? FontWeight.w600 : FontWeight.bold,
        color: enabled ? AppColor.textColor : AppColor.textColor.withOpacity(0.4),
      ),
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: Icon(icon, size: 20, color: enabled ? AppColor.primaryColor : Colors.grey),
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColor.textColor.withOpacity(0.3),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8F3EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8F3EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColor.primaryColor, width: 2),
        ),
      ),
    );
  }
}
