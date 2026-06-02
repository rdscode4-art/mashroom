import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorPanelScreen extends StatelessWidget {
  const VendorPanelScreen({super.key});

  // Derive vendor panel URL from the same base as the API
  static String get _vendorPanelUrl {
    // ApiService.imageBaseUrl is e.g. "http://192.168.1.12:5000/"
    final base = ApiService.imageBaseUrl.endsWith('/')
        ? ApiService.imageBaseUrl.substring(
            0, ApiService.imageBaseUrl.length - 1)
        : ApiService.imageBaseUrl;
    return '$base/vendor-panel';
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(_vendorPanelUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Cannot Open',
        'Could not launch the vendor panel URL.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _vendorPanelUrl));
    Get.snackbar(
      'Copied ✅',
      'Vendor panel URL copied to clipboard.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Vendor Panel',
          style: AppTypography.h3
              .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColor.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColor.primaryColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Vendor Dashboard',
              style: AppTypography.h2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Manage your products, orders, and store profile from the web panel.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColor.textColor.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // URL display card
            GestureDetector(
              onTap: () => _copyUrl(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColor.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.link_rounded,
                      color: AppColor.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _vendorPanelUrl,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded,
                      color: AppColor.primaryColor, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the URL to copy it',
              style: AppTypography.caption.copyWith(
                  color: AppColor.textColor.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 32),

            // Open in browser button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_browser_rounded,
                    color: Colors.white),
                label: Text(
                  'Open Vendor Panel',
                  style: AppTypography.buttonLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Copy button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copyUrl(context),
                icon: const Icon(Icons.copy_rounded,
                    color: AppColor.primaryColor, size: 18),
                label: Text(
                  'Copy URL',
                  style: AppTypography.buttonLarge.copyWith(
                      color: AppColor.primaryColor,
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(
                      color: AppColor.primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Info note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.blue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Open this URL in any browser on your phone or computer while connected to the same WiFi network as the server.',
                      style: AppTypography.caption.copyWith(
                          color: Colors.blue[700], height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
