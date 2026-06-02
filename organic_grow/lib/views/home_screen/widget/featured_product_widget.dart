import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/home_page_controller.dart';
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/core/models/cart_item_model.dart';
import 'package:organic_grow/core/models/product_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:organic_grow/core/controllers/wishlist_controller.dart';

class FeaturedProductWidget extends StatelessWidget {
  FeaturedProductWidget({super.key});

  final HomeController homeController = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());
  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final WishlistController wishlistController = Get.isRegistered<WishlistController>()
      ? Get.find<WishlistController>()
      : Get.put(WishlistController());

  // High-quality fallback featured products for when database is empty or offline
  final List<Product> mockFeaturedProducts = [
    Product(
      id: 'mock_p1',
      name: 'Organic Tomatoes',
      price: 120.00,
      image: 'assets/images/tomatoes.jpeg',
      rating: 4.9,
      vendorId: 'mock_v1',
      vendorName: 'Golden Green Farms',
      unit: 'kg',
    ),
    Product(
      id: 'mock_p2',
      name: 'Fresh Strawberries',
      price: 180.00,
      image: 'assets/images/strawberries.jpeg',
      rating: 4.8,
      vendorId: 'mock_v2',
      vendorName: 'Strawberry Fields',
      unit: 'pack',
    ),
    Product(
      id: 'mock_p3',
      name: 'Organic Avocado',
      price: 220.00,
      image: 'assets/images/avocado.jpeg',
      rating: 4.7,
      vendorId: 'mock_v3',
      vendorName: 'Pure Green Farms',
      unit: 'pc',
    ),
    Product(
      id: 'mock_p4',
      name: 'Fresh Organic Spinach',
      price: 60.00,
      image: 'assets/images/spinach.jpeg',
      rating: 4.6,
      vendorId: 'mock_v4',
      vendorName: 'Natures Harvest',
      unit: 'bundle',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (homeController.vendors.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Products 🌟',
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textColor,
                  ),
                ),
                Text(
                  'Healthy Picks',
                  style: AppTypography.caption.copyWith(
                    color: AppColor.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final displayProducts = homeController.featuredProducts.toList();

              if (displayProducts.isEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColor.greyColor),
                        const SizedBox(height: 12),
                        Text(
                          'No featured products currently available',
                          style: AppTypography.bodyMedium.copyWith(color: AppColor.greyColor),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.65,
                ),
                itemCount: displayProducts.length,
                itemBuilder: (context, index) {
                final product = displayProducts[index];
              
              // Resolve vendor name dynamically if empty
              String sellerName = product.vendorName;
              if (sellerName.isEmpty && product.vendorId.isNotEmpty) {
                final v = homeController.vendors.firstWhereOrNull((vendor) => vendor.id == product.vendorId);
                if (v != null) {
                  sellerName = v.shopName;
                }
              }
              if (sellerName.isEmpty) {
                sellerName = 'Organic Grow Store';
              }

              return GestureDetector(
                onTap: () => Get.toNamed('/product-detail', arguments: product),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B5E20).withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image Frame
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                child: product.image.startsWith('http')
                                    ? Image.network(
                                        product.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFFF4F9F5),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.eco_rounded,
                                              size: 40,
                                              color: AppColor.primaryColor,
                                            ),
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        product.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFFF4F9F5),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.eco_rounded,
                                              size: 40,
                                              color: AppColor.primaryColor,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                            // Rating overlay badge
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      product.rating.toStringAsFixed(1),
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Wishlist heart button overlay
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Obx(() {
                                final isFav = wishlistController.isFavorite(product.id);
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      wishlistController.toggleWishlist(product);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: isFav ? Colors.pink : AppColor.greyColor,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      
                      // Product Details Block
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColor.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sold by: $sellerName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColor.primaryColor.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${product.price.toStringAsFixed(2)}',
                                  style: AppTypography.h4.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primaryColor,
                                  ),
                                ),
                                // Cart quantity button — Obx to reactively switch between ADD and stepper
                                Obx(() {
                                  final qty = cartController.getProductQuantity(product.id);
                                  if (qty == 0) {
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        cartController.addToCart(
                                          CartItem(
                                            id: product.id,
                                            name: product.name,
                                            price: product.price,
                                            image: product.image,
                                            quantity: 1,
                                            vendorId: product.vendorId,
                                            vendorName: product.vendorName.isNotEmpty ? product.vendorName : 'Organic Store',
                                            unit: product.unit,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F3EB),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          color: AppColor.primaryColor,
                                          size: 18,
                                        ),
                                      ),
                                    );
                                  }
                                  // Quantity stepper
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {}, // absorb tap so parent card doesn't navigate
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColor.primaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => cartController.decreaseQuantity(product.id),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Icon(Icons.remove, color: Colors.white, size: 16),
                                            ),
                                          ),
                                          Text(
                                            '$qty',
                                            style: AppTypography.caption.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => cartController.increaseQuantity(product.id),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Icon(Icons.add, color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          }),
        ],
      ),
    );
    });
  }
}

class FeaturedProductWidgetShimmer extends StatelessWidget {
  const FeaturedProductWidgetShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 150, height: 20, color: Colors.grey[300]),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.65,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: double.infinity, height: 14, color: Colors.white),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(width: 50, height: 14, color: Colors.white),
                                Container(width: 24, height: 24, color: Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}