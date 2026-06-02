import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/core/controllers/vendor_controller.dart';
import 'package:organic_grow/core/models/cart_item_model.dart';
import 'package:organic_grow/core/models/product_model.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:organic_grow/views/cart_screen.dart';
import 'package:shimmer/shimmer.dart';

class VendorStoreScreen extends StatelessWidget {
  VendorStoreScreen({super.key});

  final VendorController vendorController = Get.put(VendorController());
  final CartController cartController = Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    final String vendorId = Get.arguments as String? ?? '';

    if (vendorId.isNotEmpty) {
      vendorController.loadVendorStore(vendorId);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() {
        final vendor = vendorController.selectedVendor.value;
        final isLoading = vendorController.isLoading.value;

        if (isLoading && vendor == null) {
          return const _StoreShimmer();
        }

        if (vendor == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_rounded, size: 64, color: AppColor.greyColor),
                const SizedBox(height: 16),
                Text('Store not found', style: AppTypography.h4),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        final shopImageUrl = vendor.shopImage.isNotEmpty
            ? ApiService.buildImageUrl(vendor.shopImage)
            : '';
        final shopBannerUrl = vendor.shopBanner.isNotEmpty
            ? ApiService.buildImageUrl(vendor.shopBanner)
            : shopImageUrl;

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                // 1. Collapsible App Bar with Banner
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColor.primaryColor,
                  leading: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: shopBannerUrl.isNotEmpty
                        ? Image.network(
                            shopBannerUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildBannerPlaceholder(vendor.shopName),
                          )
                        : _buildBannerPlaceholder(vendor.shopName),
                  ),
                ),

                // 2. Vendor Info Card
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop name + status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                vendor.shopName,
                                style: AppTypography.h2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: vendor.isOpen
                                    ? AppColor.primaryColor.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                vendor.isOpen ? '● Open' : '● Closed',
                                style: AppTypography.caption.copyWith(
                                  color: vendor.isOpen ? AppColor.primaryColor : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (vendor.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            vendor.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColor.greyColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Stats row: rating, delivery, min order
                        Row(
                          children: [
                            _infoChip(
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber,
                              text: vendor.rating > 0
                                  ? '${vendor.rating.toStringAsFixed(1)} (${vendor.totalReviews})'
                                  : 'New',
                            ),
                            const SizedBox(width: 16),
                            _infoChip(
                              icon: Icons.access_time_rounded,
                              iconColor: AppColor.primaryColor,
                              text: vendor.deliveryTime,
                            ),
                            if (vendor.distance != null) ...[
                              const SizedBox(width: 16),
                              _infoChip(
                                icon: Icons.directions_walk_rounded,
                                iconColor: AppColor.primaryColor,
                                text: '${vendor.distance!.toStringAsFixed(1)} km away',
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Min order
                        Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 14, color: AppColor.greyColor),
                            const SizedBox(width: 4),
                            Text(
                              'Min order: ₹${vendor.minimumOrder.toInt()}',
                              style: AppTypography.caption.copyWith(
                                color: AppColor.greyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // Cuisine tags
                        if (vendor.cuisineTags.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: vendor.cuisineTags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColor.primaryColor.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
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
                        ],
                      ],
                    ),
                  ),
                ),

                // 3. Section header: Menu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Menu 🍽️',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColor.textColor,
                      ),
                    ),
                  ),
                ),

                // 4. Products List
                Obx(() {
                  if (vendorController.isProductsLoading.value) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: List.generate(3, (_) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          )),
                        ),
                      ),
                    );
                  }

                  if (vendorController.vendorProducts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: AppColor.greyColor),
                              const SizedBox(height: 12),
                              Text(
                                'No products available',
                                style: AppTypography.bodyMedium.copyWith(color: AppColor.greyColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = vendorController.vendorProducts[index];
                          return _ProductMenuCard(
                            product: product,
                            vendorName: vendor.shopName,
                            vendorId: vendor.id,
                          );
                        },
                        childCount: vendorController.vendorProducts.length,
                      ),
                    ),
                  );
                }),
              ],
            ),

            // 5. Floating Cart Bar at Bottom
            Obx(() {
              if (cartController.cartItems.isEmpty ||
                  cartController.currentVendorId.value != vendorId) {
                return const SizedBox();
              }

              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primaryColor.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => Get.to(() => CartScreen()),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${cartController.cartItems.length} items',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '₹${cartController.totalAmount.value.toStringAsFixed(0)}',
                          style: AppTypography.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'View Cart',
                          style: AppTypography.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _infoChip({required IconData icon, required Color iconColor, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColor.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBannerPlaceholder(String shopName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B5E20),
            AppColor.primaryColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_rounded, size: 56, color: Colors.white54),
            const SizedBox(height: 8),
            Text(
              shopName,
              style: AppTypography.h3.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Individual product card in the vendor menu
class _ProductMenuCard extends StatelessWidget {
  final Product product;
  final String vendorName;
  final String vendorId;

  const _ProductMenuCard({
    required this.product,
    required this.vendorName,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return GestureDetector(
      onTap: () => Get.toNamed('/product-detail', arguments: product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: product.image.isNotEmpty
                    ? Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColor.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.image_rounded, size: 32, color: AppColor.greyColor),
                        ),
                      )
                    : Container(
                        color: AppColor.primaryColor.withOpacity(0.1),
                        child: Icon(Icons.image_rounded, size: 32, color: AppColor.greyColor),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColor.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.weight.isNotEmpty ? product.weight : '1 ${product.unit}',
                    style: AppTypography.caption.copyWith(color: AppColor.greyColor),
                  ),
                  const SizedBox(height: 8),

                  // Price row + Add button
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.primaryColor,
                        ),
                      ),
                      if (product.mrpPrice > 0 && product.mrpPrice > product.price) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${product.mrpPrice.toStringAsFixed(0)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColor.greyColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const Spacer(),

                      // Add / Quantity buttons
                      Obx(() {
                        final qty = cartController.getProductQuantity(product.id);
                        if (qty == 0) {
                          return GestureDetector(
                            onTap: () {
                              if (!product.isAvailable) {
                                Get.snackbar('Unavailable', '${product.name} is currently out of stock',
                                    snackPosition: SnackPosition.BOTTOM);
                                return;
                              }
                              cartController.addToCart(CartItem(
                                id: product.id,
                                name: product.name,
                                price: product.price,
                                image: product.image,
                                quantity: 1,
                                vendorId: vendorId,
                                vendorName: vendorName,
                                unit: product.unit,
                              ));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColor.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'ADD',
                                style: AppTypography.buttonSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        // Quantity stepper
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColor.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => cartController.decreaseQuantity(product.id),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Icon(Icons.remove, color: Colors.white, size: 18),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '$qty',
                                  style: AppTypography.buttonSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => cartController.increaseQuantity(product.id),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Icon(Icons.add, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
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
  }
}

// Shimmer loading state for entire store screen
class _StoreShimmer extends StatelessWidget {
  const _StoreShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(height: 200, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(5, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: i == 0 ? 30 : 100,
                    width: i == 0 ? 200 : double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
