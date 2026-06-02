import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/home_page_controller.dart';
import 'package:organic_grow/core/models/category_model.dart';

class CategoriesScreen extends StatelessWidget {
  CategoriesScreen({super.key});

  final HomeController homeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Cohesive background
      appBar: AppBar(
        title: Text(
          'All Categories',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Obx(() {
        if (homeController.isLoading.value) {
          return _buildLoadingState();
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: homeController.categories.length,
          itemBuilder: (context, index) {
            final category = homeController.categories[index];
            return _buildCategoryCard(context, category);
          },
        );
      }),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    final icon = _getIconFromString(category.icon);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCategoryProducts(category),
          borderRadius: BorderRadius.circular(24),
          splashColor: AppColor.primaryColor.withOpacity(0.05),
          highlightColor: AppColor.primaryColor.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon wrapper with soft circular shadow and organic gradient background
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColor.primaryColor.withOpacity(0.12),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: category.image != null && category.image!.isNotEmpty
                        ? Image.network(
                            category.image!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              icon,
                              size: 32,
                              color: AppColor.primaryColor,
                            ),
                          )
                        : Icon(
                            icon,
                            size: 32,
                            color: AppColor.primaryColor,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  category.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${category.itemCount} items',
                    style: AppTypography.caption.copyWith(
                      color: AppColor.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCategoryProducts(Category category) {
    Get.toNamed('/category-products', arguments: {'category': category});
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