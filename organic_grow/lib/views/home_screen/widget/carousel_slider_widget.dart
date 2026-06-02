import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/home_page_controller.dart';
import 'package:organic_grow/core/models/banner_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CarouselSliderWidget extends StatelessWidget {
  CarouselSliderWidget({super.key});

  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final banners = homeController.banners;
      if (banners.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          CarouselSlider(
            items: banners.map((b) => _BannerCard(banner: b)).toList(),
            options: CarouselOptions(
              height: 180,
              autoPlay: banners.length > 1,
              enlargeCenterPage: false,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: banners.length > 1,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.92,
              onPageChanged: (index, _) =>
                  homeController.updateCarouselIndex(index),
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 10),
            Obx(() => AnimatedSmoothIndicator(
                  activeIndex: homeController.currentCarouselIndex.value
                      .clamp(0, banners.length - 1),
                  count: banners.length,
                  effect: const ExpandingDotsEffect(
                    dotHeight: 7,
                    dotWidth: 7,
                    activeDotColor: AppColor.primaryColor,
                    dotColor: Colors.grey,
                  ),
                )),
          ],
        ],
      );
    });
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});
  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    final isNetwork = banner.imageUrl.startsWith('http');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.grey[200],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Image ──────────────────────────────────────────────
            isNetwork
                ? Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColor.primaryColor, strokeWidth: 2),
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported_rounded,
                          size: 40, color: Colors.grey),
                    ),
                  )
                : Image.asset(banner.imageUrl, fit: BoxFit.cover),

            // ── Gradient overlay (always) ───────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),

            // ── Title overlay (only if title is non-empty) ──────────
            if (banner.title.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Text(
                  banner.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CarouselSliderWidgetShimmer extends StatelessWidget {
  const CarouselSliderWidgetShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
