import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/core/models/cart_item_model.dart';
import 'package:organic_grow/core/models/product_model.dart';
import 'package:organic_grow/core/controllers/home_page_controller.dart';
import 'package:organic_grow/core/controllers/wishlist_controller.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:organic_grow/views/home_screen/widget/featured_product_widget.dart';

class ProductListScreen extends StatelessWidget {
  ProductListScreen({super.key});

  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final WishlistController wishlistController = Get.isRegistered<WishlistController>()
      ? Get.find<WishlistController>()
      : Get.put(WishlistController());

  // Mock list of category-specific items to make it look incredibly complete and populated!
  final Map<String, List<Product>> categoryProducts = {
    'Vegetables': [
      Product(id: 'v1', name: 'Organic Tomatoes', price: 3.99, image: 'assets/images/tomatoes.jpeg', rating: 4.8, vendorId: 'mock_v1', vendorName: 'Golden Green Farms'),
      Product(id: 'v2', name: 'Organic Spinach', price: 2.99, image: 'assets/images/spinach.jpeg', rating: 4.7, vendorId: 'mock_v4', vendorName: 'Natures Harvest'),
      Product(id: 'v3', name: 'Fresh Broccoli', price: 4.49, image: 'assets/images/broccoli.png', rating: 4.9, vendorId: 'mock_v1', vendorName: 'Golden Green Farms'),
      Product(id: 'v4', name: 'Red Carrots', price: 1.99, image: 'assets/images/carrots.png', rating: 4.5, vendorId: 'mock_v4', vendorName: 'Natures Harvest'),
    ],
    'Fruits': [
      Product(id: 'f1', name: 'Fresh Avocados', price: 5.49, image: 'assets/images/avocado.jpeg', rating: 4.6, vendorId: 'mock_v3', vendorName: 'Pure Green Farms'),
      Product(id: 'f2', name: 'Fresh Strawberries', price: 4.99, image: 'assets/images/strawberries.jpeg', rating: 4.9, vendorId: 'mock_v2', vendorName: 'Strawberry Fields'),
      Product(id: 'f3', name: 'Organic Apples', price: 3.20, image: 'assets/images/apples.png', rating: 4.8, vendorId: 'mock_v3', vendorName: 'Pure Green Farms'),
      Product(id: 'f4', name: 'Sweet Oranges', price: 2.80, image: 'assets/images/oranges.png', rating: 4.7, vendorId: 'mock_v2', vendorName: 'Strawberry Fields'),
    ],
    'Juices': [
      Product(id: 'j1', name: 'Cold Press Green Juice', price: 6.50, image: 'assets/images/green_juice.png', rating: 4.9, vendorId: 'mock_v3', vendorName: 'Pure Green Farms'),
      Product(id: 'j2', name: 'Orange Ginger Elixir', price: 5.00, image: 'assets/images/orange_juice.png', rating: 4.7, vendorId: 'mock_v2', vendorName: 'Strawberry Fields'),
      Product(id: 'j3', name: 'Fresh Carrot Juice', price: 4.50, image: 'assets/images/carrot_juice.png', rating: 4.6, vendorId: 'mock_v1', vendorName: 'Golden Green Farms'),
    ],
    'Spices': [
      Product(id: 's1', name: 'Organic Turmeric', price: 3.50, image: 'assets/images/turmeric.png', rating: 4.8, vendorId: 'mock_v1', vendorName: 'Golden Green Farms'),
      Product(id: 's2', name: 'Pure Cayenne Pepper', price: 2.90, image: 'assets/images/cayenne.png', rating: 4.5, vendorId: 'mock_v4', vendorName: 'Natures Harvest'),
      Product(id: 's3', name: 'Cinnamon Sticks', price: 4.00, image: 'assets/images/cinnamon.png', rating: 4.9, vendorId: 'mock_v3', vendorName: 'Pure Green Farms'),
    ],
    'Herbs': [
      Product(id: 'h1', name: 'Fresh Basil Leaves', price: 1.80, image: 'assets/images/basil.png', rating: 4.8, vendorId: 'mock_v4', vendorName: 'Natures Harvest'),
      Product(id: 'h2', name: 'Organic Mint', price: 1.50, image: 'assets/images/mint.png', rating: 4.7, vendorId: 'mock_v1', vendorName: 'Golden Green Farms'),
      Product(id: 'h3', name: 'Rosemary Sprigs', price: 2.00, image: 'assets/images/rosemary.png', rating: 4.9, vendorId: 'mock_v3', vendorName: 'Pure Green Farms'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    // Retrieve category name and ID safely from arguments
    String categoryName = 'Vegetables';
    String categoryId = '';
    if (Get.arguments is String) {
      categoryName = Get.arguments as String;
    } else if (Get.arguments is Map) {
      final map = Get.arguments as Map;
      final cat = map['category'];
      if (cat != null) {
        categoryName = cat.name;
        categoryId = cat.id;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '$categoryName Selection',
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
      body: FutureBuilder<List<Product>>(
        future: categoryId.isNotEmpty 
            ? ApiService.fetchProductsByCategory(categoryId)
            : Future.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const FeaturedProductWidgetShimmer();
          }

          var displayProducts = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Sub-header collection count badge
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explore Fresh Picks 🌟',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColor.textColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColor.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${displayProducts.length} Products',
                      style: AppTypography.caption.copyWith(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Gorgeous collection grid
            Expanded(
              child: displayProducts.isEmpty
                  ? const Center(
                      child: Text('No products available in this category'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
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
                                                      color: AppColor.primaryColor.withOpacity(0.06),
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
                                                      color: AppColor.primaryColor.withOpacity(0.06),
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
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Wishlist Heart Icon
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
                                          // Cart button — Obx stepper
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
                                            // Stepper
                                            return GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {},
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
                    ),
            ),
          ],
        );
      }),
    );
  }
}
