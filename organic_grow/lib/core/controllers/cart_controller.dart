import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/models/cart_item_model.dart';
import 'package:organic_grow/core/services/api_services.dart';

class CartController extends GetxController {
  var cartItems = <CartItem>[].obs;
  var totalAmount = 0.0.obs;
  var currentVendorId = ''.obs;
  var currentVendorName = ''.obs;
  var deliveryCharge = 0.0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCartFromServer();
  }

  /// Fetch cart from server on app start
  Future<void> fetchCartFromServer() async {
    try {
      isLoading.value = true;
      final data = await ApiService.fetchCart();
      if (data != null && data['cart'] != null) {
        _parseServerCart(data['cart']);
      } else {
        _clearLocalState();
      }
    } catch (e) {
      debugPrint("Failed to fetch cart: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Add item to cart via server API (handles vendor conflict)
  Future<void> addToCart(CartItem item) async {
    if (isLoading.value) return; // Guard against double-tap / double-call
    try {
      isLoading.value = true;
      final response = await ApiService.addToCart(item.id, quantity: item.quantity);

      if (response['success'] == true && response['cart'] != null) {
        // Successfully added
        _parseServerCart(response['cart']);
        Get.snackbar('Added! ✅', '${item.name} added to cart',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 1));
      } else if (response['conflict'] == true) {
        // Vendor conflict — show Zomato-style dialog
        _showVendorSwitchDialog(item);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add to cart',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Replace cart on vendor switch (user confirmed)
  Future<void> _replaceCartWithItem(CartItem item) async {
    try {
      isLoading.value = true;
      final response = await ApiService.replaceCart(item.id, quantity: 1);
      if (response['success'] == true && response['cart'] != null) {
        _parseServerCart(response['cart']);
        Get.snackbar('Cart Updated! 🔄', 'Cart replaced with ${item.vendorName} items',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to replace cart',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Increase quantity of an item
  Future<void> increaseQuantity(String productId) async {
    try {
      final item = cartItems.firstWhere((e) => e.id == productId);
      final response = await ApiService.updateCartItem(productId, item.quantity + 1);
      if (response['success'] == true) {
        if (response['cart'] != null) {
          _parseServerCart(response['cart']);
        }
      }
    } catch (e) {
      debugPrint("Failed to increase quantity: $e");
    }
  }

  /// Decrease quantity of an item
  Future<void> decreaseQuantity(String productId) async {
    try {
      final item = cartItems.firstWhere((e) => e.id == productId);
      final newQty = item.quantity - 1;
      if (newQty <= 0) {
        await removeFromCart(productId);
        return;
      }
      final response = await ApiService.updateCartItem(productId, newQty);
      if (response['success'] == true) {
        if (response['cart'] != null) {
          _parseServerCart(response['cart']);
        } else {
          _clearLocalState();
        }
      }
    } catch (e) {
      debugPrint("Failed to decrease quantity: $e");
    }
  }

  /// Remove a specific item from cart
  Future<void> removeFromCart(String productId) async {
    try {
      final response = await ApiService.removeCartItem(productId);
      if (response['success'] == true) {
        if (response['cart'] != null) {
          _parseServerCart(response['cart']);
        } else {
          _clearLocalState();
        }
      }
    } catch (e) {
      debugPrint("Failed to remove from cart: $e");
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      await ApiService.clearCart();
      _clearLocalState();
    } catch (e) {
      debugPrint("Failed to clear cart: $e");
    }
  }

  /// Get quantity of a specific product in cart (for UI buttons)
  int getProductQuantity(String productId) {
    final idx = cartItems.indexWhere((e) => e.id == productId);
    if (idx >= 0) return cartItems[idx].quantity;
    return 0;
  }

  /// Check if a product is in cart
  bool isInCart(String productId) {
    return cartItems.any((e) => e.id == productId);
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  /// Parse server cart response into local state
  void _parseServerCart(Map<String, dynamic> cartJson) {
    final vendor = cartJson['vendorId'];
    if (vendor != null && vendor is Map<String, dynamic>) {
      currentVendorId.value = vendor['_id'] ?? '';
      currentVendorName.value = vendor['shopName'] ?? '';
      deliveryCharge.value = (vendor['deliveryCharge'] ?? 0).toDouble();
    }

    final List<dynamic> products = cartJson['products'] ?? [];
    cartItems.assignAll(products.map((p) {
      final prod = p['productId'];
      String name = '';
      String image = '';
      double price = (p['price'] ?? 0).toDouble();
      String unit = 'kg';

      if (prod != null && prod is Map<String, dynamic>) {
        name = prod['productName'] ?? '';
        final imgs = prod['images'] ?? [];
        if (imgs is List && imgs.isNotEmpty) {
          image = ApiService.buildImageUrl(imgs[0].toString().replaceAll('\\', '/'));
        }
        price = (prod['sellingPrice'] ?? prod['mrpPrice'] ?? price).toDouble();
        unit = prod['unit'] ?? 'kg';
      }

      return CartItem(
        id: (prod != null && prod is Map) ? (prod['_id'] ?? '') : (p['productId'] ?? ''),
        name: name,
        price: price,
        image: image,
        quantity: p['quantity'] ?? 1,
        vendorId: currentVendorId.value,
        vendorName: currentVendorName.value,
        unit: unit,
      );
    }).toList());

    totalAmount.value = (cartJson['totalPrice'] ?? 0).toDouble();
  }

  /// Clear all local cart state
  void _clearLocalState() {
    cartItems.clear();
    totalAmount.value = 0.0;
    currentVendorId.value = '';
    currentVendorName.value = '';
    deliveryCharge.value = 0.0;
  }

  /// Clear local cart state (public accessor for logout)
  void clearLocalCart() {
    _clearLocalState();
  }


  /// Zomato-style vendor switch confirmation dialog
  void _showVendorSwitchDialog(CartItem newItem) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Replace cart items?',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Your cart contains items from "${currentVendorName.value}". '
          'Do you want to discard them and add items from "${newItem.vendorName}"?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColor.textColor.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColor.textColor.withOpacity(0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _replaceCartWithItem(newItem);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Yes, Replace',
              style: AppTypography.buttonMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}