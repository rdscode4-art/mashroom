import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/services/api_services.dart';

/// Arguments: { 'productId': String, 'vendorId': String, 'productName': String }
class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _reviewCtrl = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  late final String productId;
  late final String vendorId;
  late final String productName;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    productId = args['productId'] as String;
    vendorId = args['vendorId'] as String? ?? '';
    productName = args['productName'] as String? ?? 'Product';
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      Get.snackbar('Rating Required', 'Please select a star rating.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiService.postReview(
        productId: productId,
        vendorId: vendorId,
        rating: _rating,
        reviewText: _reviewCtrl.text.trim(),
      );
      if (res['success'] == true) {
        Get.back(result: true);
        Get.snackbar('Review Posted ✅', 'Thank you for your feedback!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Write a Review',
            style: AppTypography.h3
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Product name
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(children: [
              const Icon(Icons.shopping_bag_rounded,
                  color: AppColor.primaryColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(productName,
                    style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColor.textColor)),
              ),
            ]),
          ),
          const SizedBox(height: 28),

          // Star rating
          Text('Your Rating *',
              style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold, color: AppColor.textColor)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      key: ValueKey('$star-$_rating'),
                      color: star <= _rating ? Colors.amber : Colors.grey[400],
                      size: 44,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _rating == 0
                  ? 'Tap to rate'
                  : ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_rating],
              style: AppTypography.bodyMedium.copyWith(
                color: _rating == 0
                    ? AppColor.textColor.withValues(alpha: 0.4)
                    : Colors.amber[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Review text
          Text('Your Review (Optional)',
              style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold, color: AppColor.textColor)),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewCtrl,
            maxLines: 5,
            maxLength: 500,
            style: AppTypography.bodyMedium.copyWith(color: AppColor.textColor),
            decoration: InputDecoration(
              hintText:
                  'Share your experience with this product — quality, freshness, packaging...',
              hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColor.textColor.withValues(alpha: 0.35)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColor.textColor.withValues(alpha: 0.15))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColor.textColor.withValues(alpha: 0.15))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColor.primaryColor, width: 1.8)),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Submit Review',
                      style: AppTypography.buttonLarge.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}
