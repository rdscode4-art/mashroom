import 'package:flutter/material.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Terms of Service', style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text('Terms of Service Agreement', style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold, color: AppColor.textColor)),
            const SizedBox(height: 8),
            Text('Last updated: May 18, 2026', style: AppTypography.caption.copyWith(color: AppColor.textColor.withOpacity(0.4))),
            const SizedBox(height: 24),
            _buildDocCard(
              context,
              title: '1. User Obligations',
              body: 'By utilizing RiFresh INDIA, you represent that you provide correct, up-to-date account registry details and agree to abide by active country-level agricultural standards.',
            ),
            const SizedBox(height: 16),
            _buildDocCard(
              context,
              title: '2. Payment Terms',
              body: 'All financial processes occur securely at purchase checkouts. Inaccurate billing addresses or delayed transactions might cause cancellations or postponement of delivery dates.',
            ),
            const SizedBox(height: 16),
            _buildDocCard(
              context,
              title: '3. Intellectual Rights',
              body: 'All custom brand images, text layouts, user interfaces, vector designs, and algorithms embedded in RiFresh INDIA belong to our developers and are protected under global copyright regulations.',
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
