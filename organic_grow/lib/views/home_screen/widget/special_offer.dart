import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/offer_controller.dart';
import 'package:organic_grow/core/models/offer_model.dart';
import 'package:shimmer/shimmer.dart';

class SpecialOffersWidget extends StatelessWidget {
  SpecialOffersWidget({super.key});

  final OfferController offerController = Get.isRegistered<OfferController>()
      ? Get.find<OfferController>()
      : Get.put(OfferController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (offerController.isLoading.value) {
        return const SpecialOffersWidgetShimmer();
      }

      final offers = offerController.offers;
      if (offers.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Offers 🏷️',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.textColor,
              ),
            ),
            const SizedBox(height: 14),
            // Carousel — no dots
            CarouselSlider(
              items: offers.map((offer) => _OfferCard(offer: offer)).toList(),
              options: CarouselOptions(
                height: 150,
                autoPlay: offers.length > 1,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayCurve: Curves.fastOutSlowIn,
                autoPlayAnimationDuration: const Duration(milliseconds: 700),
                enableInfiniteScroll: offers.length > 1,
                viewportFraction: 1.0,
                // No page indicator — no dots
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SINGLE OFFER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final hasImage = offer.image.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: hasImage
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image (if set) ──────────────────────────
            if (hasImage)
              Image.network(
                offer.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                    ),
                  ),
                ),
              ),

            // ── Dark overlay when image is present ─────────────────
            if (hasImage)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Decorative circles (no-image mode) ─────────────────
            if (!hasImage) ...[
              Positioned(
                bottom: -40,
                right: -20,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              Positioned(
                top: -20,
                left: 120,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ],

            // ── Content row ────────────────────────────────────────
            Row(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          offer.badgeText,
                          style: AppTypography.caption.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Discount text
                      Text(
                        offer.discountText,
                        style: AppTypography.h2.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        offer.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Right icon (only when no image) ──────────────────
              if (!hasImage)
                Container(
                  width: 110,
                  alignment: Alignment.center,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(Icons.discount_rounded,
                        color: Colors.white, size: 44),
                  ]),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────
class SpecialOffersWidgetShimmer extends StatelessWidget {
  const SpecialOffersWidgetShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 120, height: 20, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
