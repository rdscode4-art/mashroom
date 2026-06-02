import 'package:flutter/material.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Privacy Policy', style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text('Your Privacy Matters', style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold, color: AppColor.textColor)),
            const SizedBox(height: 8),
            Text('Last updated: May 18, 2026', style: AppTypography.caption.copyWith(color: AppColor.textColor.withOpacity(0.4))),
            const SizedBox(height: 24),
            _buildDocCard(
              context,
              title: '1. Information We Collect',
              body: 'We collect personal details such as your name, email, phone number, and shipping address when you interact with our app. This allows us to handle purchases and execute home delivery processes.',
            ),
            const SizedBox(height: 16),
            _buildDocCard(
              context,
              title: '2. How We Use Data',
              body: 'Your data is utilized strictly to customize your ordering process, improve application speed, prevent bad billing practices, and send optional promotional alerts matching your healthy lifestyle choices.',
            ),
            const SizedBox(height: 16),
            _buildDocCard(
              context,
              title: '3. Data Security',
              body: 'We protect your records using industry-grade SSL encryption and secure cloud-hosted databases. We never distribute, sell, or loan your database information under any circumstances.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(BuildContext context, {required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColor.primaryColor)),
          const SizedBox(height: 12),
          Text(body, style: AppTypography.bodyMedium.copyWith(color: AppColor.textColor.withOpacity(0.6), height: 1.5)),
        ],
      ),
    );
  }
}
