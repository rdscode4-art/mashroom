import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'How do I track my order?', 'a': 'You can track your order status in real time inside the Order History page under My Account details.'},
      {'q': 'What are your delivery hours?', 'a': 'We deliver fresh produce daily from 7:00 AM to 9:00 PM, including weekends.'},
      {'q': 'Are all products 100% organic?', 'a': 'Absolutely! All products listed on RiFresh INDIA are directly sourced from certified organic local farmers.'},
      {'q': 'How do I cancel my order?', 'a': 'Orders can be cancelled within 15 minutes of ordering. Go to Order History and click Cancel.'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Help & Support', style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frequently Asked Questions', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: AppColor.textColor)),
            const SizedBox(height: 16),
            ...faqs.map((faq) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    title: Text(faq['q']!, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColor.textColor)),
                    childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    children: [
                      Text(faq['a']!, style: AppTypography.bodyMedium.copyWith(color: AppColor.textColor.withOpacity(0.6))),
                    ],
                  ),
                )),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColor.primaryColor.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColor.primaryColor,
                    radius: 26,
                    child: Icon(Icons.headset_mic_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Still need support?', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColor.textColor)),
                        const SizedBox(height: 4),
                        Text('Our experts are here 24/7.', style: AppTypography.caption.copyWith(color: AppColor.textColor.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.snackbar(
                        'Support Request',
                        'Customer representative will contact you shortly.',
                        backgroundColor: AppColor.primaryColor,
                        colorText: Colors.white,
                        borderRadius: 16,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Connect'),
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
