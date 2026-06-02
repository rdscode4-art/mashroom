import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/home_page_controller.dart';
import 'package:organic_grow/core/controllers/dashBoard_controller.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesSectionWidget extends StatelessWidget {
  CategoriesSectionWidget({super.key});

  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row with "See All"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "What's on your mind? 🌿",
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColor.textColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  try {
                    final DashBoardController dashController = Get.find<DashBoardController>();
                    dashController.onTabChange(1); // Navigates to Categories tab
                  } catch (_) {
                    Get.toNamed('/categories');
                  }
                },
                child: Text(
                  'See All',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColor.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Zomato style Single-Row circular categories horizontal scrolling list
        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: homeController.categories.length,
            itemBuilder: (context, index) {
              final category = homeController.categories[index];
              final icon = _getIconFromString(category.icon);

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => Get.toNamed('/category-products', arguments: {'category': category}),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Premium tapable category icon card (circular)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey[100]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: ClipOval(
                            child: category.image != null && category.image!.isNotEmpty
                                ? Image.network(
                                    category.image!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColor.primaryColor.withOpacity(0.06),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon, color: AppColor.primaryColor, size: 24),
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColor.primaryColor.withOpacity(0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      icon,
                                      color: AppColor.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'local_florist':
        return Icons.local_florist_rounded;
      case 'emoji_food_beverage':
        return Icons.emoji_food_beverage_rounded;
      case 'local_drink':
        return Icons.local_drink_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'spa':
        return Icons.spa_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

class CategoriesSectionWidgetShimmer extends StatelessWidget {
  const CategoriesSectionWidgetShimmer({super.key});

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
              Container(width: 140, height: 20, color: Colors.grey[300]),
              Container(width: 50, height: 14, color: Colors.grey[300]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(width: 45, height: 10, color: Colors.white),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
