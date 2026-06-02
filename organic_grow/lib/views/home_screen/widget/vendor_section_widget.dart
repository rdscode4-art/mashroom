import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/home_page_controller.dart';
import 'package:organic_grow/core/models/vendor_model.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:shimmer/shimmer.dart';

class VendorSectionWidget extends StatelessWidget {
  VendorSectionWidget({super.key});

  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Stores 🏪',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColor.textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.toNamed('/all-vendors');
                },
                child: Text(
                  'See All',
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppColor.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Scrollable Zomato-style filter pills
        SizedBox(
          height: 38,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildFilterChip('All Stores', ''),
              _buildFilterChip('Nearest 📍', 'nearest'),
              _buildFilterChip('Rating 4.0+ ⭐', 'rating'),
              _buildFilterChip('Open Now 🟢', 'open'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Obx(() {
          if (homeController.vendors.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.explore_outlined, size: 40, color: AppColor.primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Service Not Available 📍',
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We are currently expanding! We are not serving in your area yet.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.grey[500],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (homeController.filteredVendors.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.store_rounded, size: 48, color: AppColor.greyColor),
                      const SizedBox(height: 12),
                      Text(
                        'No stores match the active filter',
                        style: AppTypography.bodyMedium.copyWith(color: AppColor.greyColor),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: homeController.filteredVendors.length,
            itemBuilder: (context, index) {
              return _VendorCard(vendor: homeController.filteredVendors[index]);
            },
          );
        }),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() {
      final isSelected = homeController.selectedFilter.value == value;
      return GestureDetector(
        onTap: () {
          homeController.selectedFilter.value = value;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColor.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColor.primaryColor : Colors.grey[200]!,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColor.primaryColor.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white : AppColor.textColor.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _VendorCard extends StatelessWidget {
  final Vendor vendor;
  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final String shopImageUrl = vendor.shopImage.isNotEmpty
        ? ApiService.buildImageUrl(vendor.shopImage)
        : '';

    return GestureDetector(
      onTap: () {
        Get.toNamed('/vendor-store', arguments: vendor.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop banner/image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: shopImageUrl.isNotEmpty
                    ? Image.network(
                        shopImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderBanner(),
                      )
                    : _buildPlaceholderBanner(),
              ),
            ),
            // Vendor details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Name + Open/Closed badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vendor.shopName,
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColor.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: vendor.isOpen
                              ? AppColor.primaryColor.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          vendor.isOpen ? 'Open' : 'Closed',
                          style: AppTypography.caption.copyWith(
                            color: vendor.isOpen ? AppColor.primaryColor : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Rating, Delivery time, Distance (Hiding delivery charge)
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColor.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              vendor.rating > 0 ? vendor.rating.toStringAsFixed(1) : 'New',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Delivery time
                      Icon(Icons.access_time_rounded, size: 14, color: AppColor.greyColor),
                      const SizedBox(width: 4),
                      Text(
                        vendor.deliveryTime,
                        style: AppTypography.caption.copyWith(
                          color: AppColor.greyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // Distance display (If available)
                      if (vendor.distance != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.directions_walk_rounded, size: 14, color: AppColor.greyColor),
                        const SizedBox(width: 4),
                        Text(
                          '${vendor.distance!.toStringAsFixed(1)} km',
                          style: AppTypography.caption.copyWith(
                            color: AppColor.greyColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 3: Cuisine tags
                  if (vendor.cuisineTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: vendor.cuisineTags.take(4).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColor.primaryColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.caption.copyWith(
                              color: AppColor.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Address
                  if (vendor.fullAddress.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: AppColor.greyColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vendor.fullAddress,
                            style: AppTypography.caption.copyWith(
                              color: AppColor.greyColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primaryColor.withOpacity(0.15),
            AppColor.secondaryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_rounded, size: 48, color: AppColor.primaryColor.withOpacity(0.4)),
            const SizedBox(height: 6),
            Text(
              vendor.shopName,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColor.primaryColor.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer placeholder for vendor section loading
class VendorSectionWidgetShimmer extends StatelessWidget {
  const VendorSectionWidgetShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 160,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(2, (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        )),
      ],
    );
  }
}
