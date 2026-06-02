import 'package:flutter/material.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('About App', style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/logo.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text('RiFresh INDIA', style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold, color: AppColor.textColor)),
            const SizedBox(height: 8),
            Text('Version 1.0.0 (Build #2026)', style: AppTypography.caption.copyWith(color: AppColor.textColor.withOpacity(0.4))),
            const SizedBox(height: 32),
            Text(
              'RiFresh INDIA is built to deliver clean, pesticide-free, premium organic produce directly from sustainable local farms to healthy households. We are proud to support local agriculture and environmentally conscious farming practices.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColor.textColor.withOpacity(0.6), height: 1.6),
            ),
            const SizedBox(height: 48),
            Text('© 2026 RiFresh INDIA Inc.', style: AppTypography.caption.copyWith(color: AppColor.textColor.withOpacity(0.3))),
            Text('All Rights Reserved.', style: AppTypography.caption.copyWith(color: AppColor.textColor.withOpacity(0.3))),
          ],
        ),
      ),
    );
  }
}
