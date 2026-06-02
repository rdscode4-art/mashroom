import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/core/models/product_model.dart';
import 'package:organic_grow/core/services/api_services.dart';

class WishlistController extends GetxController {
  var wishlistItems = <Product>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWishlistFromServer();
  }

  /// Fetch wishlist from server
  Future<void> fetchWishlistFromServer() async {
    try {
      isLoading.value = true;
      final data = await ApiService.fetchWishlist();
      if (data != null && data['wishlist'] != null) {
        final List<dynamic> productsJson = data['wishlist']['productIds'] ?? [];
        wishlistItems.assignAll(productsJson.map((json) {
          final product = Product.fromJson(json);
          return Product(
            id: product.id,
            name: product.name,
            price: product.price,
            mrpPrice: product.mrpPrice,
            image: ApiService.buildImageUrl(product.image),
            images: product.images.map((e) => ApiService.buildImageUrl(e)).toList(),
            rating: product.rating == 0 ? 4.5 : product.rating,
            categoryId: product.categoryId,
            categoryName: product.categoryName,
            description: product.description,
            unit: product.unit,
            weight: product.weight,
            stock: product.stock,
            vendorId: product.vendorId,
            vendorName: product.vendorName,
            isAvailable: product.isAvailable,
            isFeatured: product.isFeatured,
          );
        }).toList());
      } else {
        wishlistItems.clear();
      }
    } catch (e) {
      debugPrint("Failed to fetch wishlist: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle product in wishlist (adds if not present, removes if present)
  Future<void> toggleWishlist(Product product) async {
    final isFav = isFavorite(product.id);
    if (isFav) {
      await removeFromWishlist(product.id);
    } else {
      await addToWishlist(product);
    }
  }

  /// Add product to wishlist
  Future<void> addToWishlist(Product product) async {
    try {
      // Local updates first for instant feedback (Optimistic Update)
      if (!wishlistItems.any((item) => item.id == product.id)) {
        wishlistItems.add(product);
      }
      
      final response = await ApiService.addToWishlist(product.id);
      if (response['success'] == true) {
        Get.snackbar(
          'Added to Wishlist 💖',
          '${product.name} has been added to your wishlist!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );
      }
      fetchWishlistFromServer();
    } catch (e) {
      debugPrint("Failed to add to wishlist: $e");
      wishlistItems.removeWhere((item) => item.id == product.id);
      Get.snackbar('Error', 'Failed to add to wishlist', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String productId) async {
    Product? removedProduct;
    int? removedIndex;
    
    try {
      final index = wishlistItems.indexWhere((item) => item.id == productId);
      if (index >= 0) {
        removedProduct = wishlistItems[index];
        removedIndex = index;
        wishlistItems.removeAt(index);
      }

      final response = await ApiService.removeFromWishlist(productId);
      if (response['success'] == true) {
        if (removedProduct != null) {
          Get.snackbar(
            'Removed 💔',
            '${removedProduct.name} removed from wishlist.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 1),
          );
        }
      }
      fetchWishlistFromServer();
    } catch (e) {
      debugPrint("Failed to remove from wishlist: $e");
      if (removedProduct != null && removedIndex != null) {
        wishlistItems.insert(removedIndex, removedProduct);
      }
      Get.snackbar('Error', 'Failed to remove from wishlist', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Check if a product is in wishlist
  bool isFavorite(String productId) {
    return wishlistItems.any((item) => item.id == productId);
  }
}
