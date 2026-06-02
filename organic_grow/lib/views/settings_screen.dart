import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final SettingsController settingsController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Soft organic background
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Settings Group
            _buildSectionTitle('App Settings'),
            const SizedBox(height: 8),
            _buildGroupContainer([
              Obx(() => _buildSwitchSetting(
                'Dark Mode',
                'Enable dark theme',
                Icons.dark_mode_rounded,
                settingsController.isDarkMode.value,
                (value) => settingsController.toggleDarkMode(value),
                Colors.indigo,
              )),
            ]),
            
            const SizedBox(height: 20),
            
            // Support Group
            _buildSectionTitle('Support & Help'),
            const SizedBox(height: 8),
            _buildGroupContainer([
              _buildSettingsItem(
                Icons.help_center_rounded,
                'Help Center',
                'Get help with the app',
                () => Get.toNamed('/help'),
                Colors.teal,
              ),
              Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
              _buildSettingsItem(
                Icons.privacy_tip_rounded,
                'Privacy Policy',
                'Read our privacy policy',
                () => Get.toNamed('/privacy'),
                Colors.blue,
              ),
              Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
              _buildSettingsItem(
                Icons.description_rounded,
                'Terms of Service',
                'Read our terms of service',
                () => Get.toNamed('/terms'),
                Colors.orange,
              ),
            ]),
            
            const SizedBox(height: 20),
            
            // About Group
            _buildSectionTitle('App Info'),
            const SizedBox(height: 8),
            _buildGroupContainer([
              _buildSettingsItem(
                Icons.info_rounded,
                'About App',
                'Version 1.0.0',
                () => Get.toNamed('/about'),
                Colors.purple,
              ),
              Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
              _buildSettingsItem(
                Icons.star_rate_rounded,
                'Rate App',
                'Rate us on App Store',
                () => _rateApp(),
                Colors.pink,
              ),
              Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
              _buildSettingsItem(
                Icons.share_rounded,
                'Share App',
                'Share with friends',
                () => _shareApp(),
                Colors.cyan,
              ),
            ]),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColor.textColor.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    final context = Get.context!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchSetting(
    String title, 
    String subtitle, 
    IconData icon, 
    bool value, 
    Function(bool) onChanged,
    Color iconColor,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColor.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(
          color: AppColor.textColor.withOpacity(0.4),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColor.primaryColor,
        activeTrackColor: AppColor.primaryColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon, 
    String title, 
    String subtitle, 
    VoidCallback onTap,
    Color iconColor,
  ) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColor.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(
          color: AppColor.textColor.withOpacity(0.4),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColor.textColor.withOpacity(0.3),
      ),
    );
  }

  void _rateApp() {
    Get.snackbar(
      'Rate App',
      'Thank you! Redirecting to App Store...',
      backgroundColor: AppColor.primaryColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.star_rounded, color: Colors.white),
    );
  }

  void _shareApp() {
    Get.snackbar(
      'Share App',
      'Link copied! Share RiFresh India with friends.',
      backgroundColor: AppColor.primaryColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.share_rounded, color: Colors.white),
    );
  }
}