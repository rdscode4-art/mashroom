import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/wishlist_controller.dart';
import 'package:organic_grow/core/models/product_model.dart';
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/core/models/cart_item_model.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WishlistController wishlistController = Get.isRegistered<WishlistController>()
        ? Get.find<WishlistController>()
        : Get.put(WishlistController());
    final CartController cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController());

    // Trigger fetch on build to guarantee up-to-date items
    wishlistController.fetchWishlistFromServer();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Wishlist 💖',
          style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Obx(() {
        if (wishlistController.isLoading.value && wishlistController.wishlistItems.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColor.primaryColor));
        }

        if (wishlistController.wishlistItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 64, color: AppColor.greyColor.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Your wishlist is empty',
                  style: AppTypography.bodyLarge.copyWith(color: AppColor.textColor.withOpacity(0.5)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Discover Products'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColor.primaryColor,
          onRefresh: () => wishlistController.fetchWishlistFromServer(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: wishlistController.wishlistItems.length,
            itemBuilder: (context, index) {
              final Product product = wishlistController.wishlistItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => Get.toNamed('/product-detail', arguments: product),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Product image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: product.image.isNotEmpty
                                ? (product.image.startsWith('http')
                                    ? Image.network(product.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildFallbackIcon())
                                    : Image.asset(product.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildFallbackIcon()))
                                : _buildFallbackIcon(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: AppTypography.caption.copyWith(color: AppColor.textColor.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)} / ${product.unit}',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColor.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Quick add to cart button!
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColor.primaryColor, size: 20),
                                    onPressed: () {
                                      cartController.addToCart(CartItem(
                                        id: product.id,
                                        name: product.name,
                                        price: product.price,
                                        image: product.image,
                                        quantity: 1,
                                        vendorId: product.vendorId,
                                        vendorName: product.vendorName.isNotEmpty ? product.vendorName : 'Organic Store',
                                        unit: product.unit,
                                      ));
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded, color: Colors.pink),
                          onPressed: () {
                            wishlistController.removeFromWishlist(product.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: AppColor.primaryColor.withOpacity(0.06),
      child: const Icon(Icons.eco_rounded, color: AppColor.primaryColor, size: 36),
    );
  }
}
