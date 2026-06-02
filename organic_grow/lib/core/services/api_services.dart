import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:organic_grow/core/models/category_model.dart';
import 'package:organic_grow/core/models/offer_model.dart';
import 'package:organic_grow/core/models/product_model.dart';
import 'package:organic_grow/core/models/vendor_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart' hide Response, MultipartFile, FormData;
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/core/controllers/wishlist_controller.dart';

class ApiService {
  static const String baseUrl =
      'https://mushroomback.ridealdigitalseva.com/api';
  static const String imageBaseUrl =
      'https://mushroomback.ridealdigitalseva.com/';

  static final Dio _dio = _initDio();

  // Helper method to setup Dio with logging and token interceptors
  static Dio _initDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors(dio);
    return dio;
  }

  // Global static token holder to persist in memory during app session
  static String? userToken;
  static const String _tokenKey = 'user_token';

  // Loads the saved token from local storage
  static Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userToken = prefs.getString(_tokenKey);
      if (userToken != null && userToken!.isNotEmpty) {
        initInterceptors();
        // Load cart and wishlist from server once token is loaded
        _fetchUserDataOnTokenChange();
      }
    } catch (e) {
      debugPrint("Failed to load saved token: $e");
    }
  }

  // Persists the token into local storage
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      userToken = token;
      initInterceptors();
      // Load cart and wishlist from server once token is saved
      _fetchUserDataOnTokenChange();
    } catch (e) {
      debugPrint("Failed to save token: $e");
    }
  }

  // Clears the token from local storage (on Logout)
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      userToken = null;
      initInterceptors();
      // Clear cart and wishlist on logout
      _clearUserDataOnLogout();
    } catch (e) {
      debugPrint("Failed to clear token: $e");
    }
  }

  // Helper helper to fetch cart and wishlist on token load/save
  static void _fetchUserDataOnTokenChange() {
    try {
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().fetchCartFromServer();
      }
      if (Get.isRegistered<WishlistController>()) {
        Get.find<WishlistController>().fetchWishlistFromServer();
      }
    } catch (e) {
      debugPrint("Failed to load user data on token change: $e");
    }
  }

  // Helper helper to clear cart and wishlist on logout
  static void _clearUserDataOnLogout() {
    try {
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().clearLocalCart();
      }
      if (Get.isRegistered<WishlistController>()) {
        Get.find<WishlistController>().wishlistItems.clear();
      }
    } catch (e) {
      debugPrint("Failed to clear user data on logout: $e");
    }
  }

  // Initialize/re-initialize logging and header interceptors
  static void initInterceptors() {
    _setupInterceptors(_dio);
  }

  // Configures requests to output clean cURL and response structures to debug log
  static void _setupInterceptors(Dio dioInstance) {
    dioInstance.interceptors.clear();
    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (userToken != null && userToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $userToken';
          }

          // Print cURL representation of request to debug console
          debugPrint("\n🚀 [Dio Request cURL]");
          debugPrint(_requestToCurl(options));
          debugPrint(
            "--------------------------------------------------------------------------------\n",
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Print successful response details
          debugPrint("\n✅ [Dio Response SUCCESS]");
          debugPrint(
            "STATUS: ${response.statusCode} ${response.statusMessage}",
          );
          debugPrint("URL: ${response.requestOptions.uri}");
          debugPrint("DATA: ${jsonEncode(response.data)}");
          debugPrint(
            "================================================================================\n",
          );

          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Print error response details
          debugPrint("\n❌ [Dio Response ERROR]");
          debugPrint(
            "STATUS: ${e.response?.statusCode} ${e.response?.statusMessage}",
          );
          debugPrint("URL: ${e.requestOptions.uri}");
          debugPrint("ERROR: ${e.message}");
          debugPrint(
            "RESPONSE DATA: ${e.response?.data != null ? jsonEncode(e.response?.data) : 'No response body'}",
          );
          debugPrint(
            "================================================================================\n",
          );

          return handler.next(e);
        },
      ),
    );
  }

  // Translates options into shell-executable cURL equivalent
  static String _requestToCurl(RequestOptions options) {
    List<String> curlParts = ['curl -i'];
    curlParts.add('-X ${options.method.toUpperCase()}');

    options.headers.forEach((key, value) {
      if (key != 'cookie') {
        curlParts.add('-H "$key: $value"');
      }
    });

    if (options.data != null) {
      final requestBody = options.data is Map || options.data is List
          ? jsonEncode(options.data)
          : options.data.toString();
      curlParts.add('-d \'$requestBody\'');
    }

    final String finalUrl = options.path.startsWith('http')
        ? options.path
        : '${options.baseUrl}${options.path}';
    curlParts.add('"$finalUrl"');

    return curlParts.join(' \\\n  ');
  }

  // Helper to build full image URL from backend path
  static String buildImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$imageBaseUrl${path.replaceAll('\\', '/')}';
  }

  // ==========================================
  // AUTHENTICATION APIs
  // ==========================================

  /// Sends a 4-digit OTP to the user's phone number
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: {'phone': phone},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to send OTP. Connection error.',
      );
    }
  }

  /// Verifies the OTP and returns the user payload and JWT token
  static Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['token'] != null) {
        await saveToken(data['token']); // Save and persist token
      }
      return data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Invalid OTP verification failed.',
      );
    }
  }

  /// Fetches the authenticated user profile using authorization token
  static Future<Map<String, dynamic>> fetchProfile() async {
    try {
      initInterceptors(); // Ensure interceptors are active
      final response = await _dio.get('/auth/profile');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch user profile.',
      );
    }
  }

  /// Updates user location coordinates and address details on backend
  static Future<Map<String, dynamic>> updateLocation({
    required double latitude,
    required double longitude,
    String? fullAddress,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      initInterceptors(); // Ensure authorization token header is appended
      final response = await _dio.put(
        '/auth/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (fullAddress != null) 'fullAddress': fullAddress,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
          if (pincode != null) 'pincode': pincode,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update user location.',
      );
    }
  }

  /// Registers or updates a user profile on the backend
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String fullAddress,
    required String city,
    required String state,
    required String pincode,
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    try {
      initInterceptors(); // Ensure authorization token header is appended
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'role': role,
          'fullAddress': fullAddress,
          'city': city,
          'state': state,
          'pincode': pincode,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed.');
    }
  }

  // ==========================================
  // CATEGORY APIs
  // ==========================================

  // Fetch categories dynamically from backend database
  static Future<List<Category>> fetchCategories() async {
    try {
      final response = await _dio.get('/categories');
      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['categories'] ?? [];
        return list
            .map(
              (json) => Category(
                id: json['_id'] ?? '',
                name: json['name'] ?? '',
                icon: json['icon'] ?? 'local_florist',
                image:
                    (json['image'] != null &&
                        (json['image'] as String).isNotEmpty)
                    ? buildImageUrl(json['image'] as String)
                    : null,
                itemCount: (json['productCount'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch categories: $e");
      return [];
    }
  }

  // ==========================================
  // PRODUCT APIs
  // ==========================================

  // Fetch all products (for featured section)
  static Future<List<Product>> fetchFeaturedProducts({
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.get(
        '/products',
        queryParameters: {
          'featured': 'true',
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['products'] ?? [];
        return list.map((json) {
          final product = Product.fromJson(json);
          // Build full image URL
          return Product(
            id: product.id,
            name: product.name,
            price: product.price,
            mrpPrice: product.mrpPrice,
            image: buildImageUrl(product.image),
            images: product.images.map((e) => buildImageUrl(e)).toList(),
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
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch featured products: $e");
      return [];
    }
  }

  // Fetch products by category
  static Future<List<Product>> fetchProductsByCategory(
    String categoryId, {
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.get(
        '/products',
        queryParameters: {
          'category': categoryId,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['products'] ?? [];
        return list.map((json) {
          final product = Product.fromJson(json);
          return Product(
            id: product.id,
            name: product.name,
            price: product.price,
            mrpPrice: product.mrpPrice,
            image: buildImageUrl(product.image),
            images: product.images.map((e) => buildImageUrl(e)).toList(),
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
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch products by category: $e");
      return [];
    }
  }

  // Search products by name
  static Future<List<Product>> searchProducts(
    String query, {
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.get(
        '/products',
        queryParameters: {
          'q': query,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['products'] ?? [];
        return list.map((json) {
          final product = Product.fromJson(json);
          return Product(
            id: product.id,
            name: product.name,
            price: product.price,
            mrpPrice: product.mrpPrice,
            image: buildImageUrl(product.image),
            images: product.images.map((e) => buildImageUrl(e)).toList(),
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
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Failed to search products: $e");
      return [];
    }
  }

  // ==========================================
  // VENDOR APIs 🏪
  // ==========================================

  /// Fetch all approved vendors
  static Future<List<Vendor>> fetchVendors() async {
    try {
      final response = await _dio.get('/vendors');
      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['vendors'] ?? [];
        return list.map((json) => Vendor.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch vendors: $e");
      return [];
    }
  }

  /// Fetch nearby vendors based on user location
  static Future<List<Vendor>> fetchNearbyVendors(
    double lat,
    double lng, {
    double radius = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/vendors/nearby',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radius},
      );
      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['vendors'] ?? [];
        return list.map((json) => Vendor.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch nearby vendors: $e");
      return [];
    }
  }

  /// Fetch single vendor detail
  static Future<Vendor?> fetchVendorById(String vendorId) async {
    try {
      final response = await _dio.get('/vendors/$vendorId');
      if (response.data['success'] == true) {
        return Vendor.fromJson(response.data['vendor']);
      }
      return null;
    } catch (e) {
      debugPrint("Failed to fetch vendor: $e");
      return null;
    }
  }

  /// Fetch all products of a specific vendor
  static Future<List<Product>> fetchVendorProducts(String vendorId) async {
    try {
      final response = await _dio.get('/vendors/$vendorId/products');
      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['products'] ?? [];
        return list.map((json) {
          final product = Product.fromJson(json);
          return Product(
            id: product.id,
            name: product.name,
            price: product.price,
            mrpPrice: product.mrpPrice,
            image: buildImageUrl(product.image),
            images: product.images.map((e) => buildImageUrl(e)).toList(),
            rating: product.rating,
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
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch vendor products: $e");
      return [];
    }
  }

  // ==========================================
  // VENDOR PANEL APIs (Protected)
  // ==========================================

  /// Fetch Vendor Dashboard Stats
  static Future<Map<String, dynamic>?> fetchVendorDashboard() async {
    try {
      initInterceptors();
      final response = await _dio.get('/vendors/panel/dashboard');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Failed to fetch vendor dashboard: $e");
      return null;
    }
  }

  /// Toggle Shop Open/Close Status
  static Future<Map<String, dynamic>?> toggleShopStatus() async {
    try {
      initInterceptors();
      final response = await _dio.put('/vendors/panel/toggle-shop');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Failed to toggle shop status: $e");
      return null;
    }
  }

  // ==========================================
  // CART APIs 🛒 (Server-Side)
  // ==========================================

  /// Fetch user's current cart from server
  static Future<Map<String, dynamic>?> fetchCart() async {
    try {
      initInterceptors();
      final response = await _dio.get('/cart');
      if (response.data['success'] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint("Failed to fetch cart: $e");
      return null;
    }
  }

  /// Add item to cart (handles vendor conflict with 409 response)
  /// Returns: { success: true, cart: {...} } or { success: false, conflict: true, ... }
  static Future<Map<String, dynamic>> addToCart(
    String productId, {
    int quantity = 1,
  }) async {
    try {
      initInterceptors();
      final response = await _dio.post(
        '/cart/add',
        data: {'productId': productId, 'quantity': quantity},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Vendor conflict — return the conflict data for UI to handle
        return e.response?.data as Map<String, dynamic>;
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to add to cart.');
    }
  }

  /// Replace cart (user confirmed vendor switch)
  static Future<Map<String, dynamic>> replaceCart(
    String productId, {
    int quantity = 1,
  }) async {
    try {
      initInterceptors();
      final response = await _dio.post(
        '/cart/replace',
        data: {'productId': productId, 'quantity': quantity},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to replace cart.');
    }
  }

  /// Update cart item quantity
  static Future<Map<String, dynamic>> updateCartItem(
    String productId,
    int quantity,
  ) async {
    try {
      initInterceptors();
      final response = await _dio.put(
        '/cart/update',
        data: {'productId': productId, 'quantity': quantity},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update cart.');
    }
  }

  /// Remove single item from cart
  static Future<Map<String, dynamic>> removeCartItem(String productId) async {
    try {
      initInterceptors();
      final response = await _dio.delete('/cart/remove/$productId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to remove item.');
    }
  }

  /// Clear entire cart
  static Future<Map<String, dynamic>> clearCart() async {
    try {
      initInterceptors();
      final response = await _dio.delete('/cart/clear');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to clear cart.');
    }
  }

  // ==========================================
  // WISHLIST APIs 💖 (Server-Side)
  // ==========================================

  /// Fetch user's wishlist from server
  static Future<Map<String, dynamic>?> fetchWishlist() async {
    try {
      initInterceptors();
      final response = await _dio.get('/wishlist');
      if (response.data['success'] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint("Failed to fetch wishlist: $e");
      return null;
    }
  }

  /// Add item to wishlist
  static Future<Map<String, dynamic>> addToWishlist(String productId) async {
    try {
      initInterceptors();
      final response = await _dio.post(
        '/wishlist/add',
        data: {'productId': productId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to add to wishlist.',
      );
    }
  }

  /// Remove item from wishlist
  static Future<Map<String, dynamic>> removeFromWishlist(
    String productId,
  ) async {
    try {
      initInterceptors();
      final response = await _dio.delete('/wishlist/remove/$productId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to remove from wishlist.',
      );
    }
  }

  // ==========================================
  // BANNER (mock for now)
  // ==========================================

  // Fetch banners (mock compatibility layer for existing screens)
  static Future<List<String>> fetchBanners() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return [
      "assets/banner_images/banner1.jpg",
      "assets/banner_images/banner2.png",
      "assets/banner_images/banner3.png",
    ];
  }

  // ==========================================
  // PROFILE UPDATE
  // ==========================================

  /// Update user profile (name, email) on backend
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      initInterceptors();
      final response = await _dio.put(
        '/auth/profile',
        data: {'name': name, 'email': email},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile.',
      );
    }
  }

  /// Upload profile photo — sends image as multipart form-data
  static Future<Map<String, dynamic>> uploadProfilePhoto(
    String filePath,
  ) async {
    try {
      initInterceptors();
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
      final response = await _dio.post('/auth/profile/photo', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to upload profile photo.',
      );
    }
  }

  // ==========================================
  // ORDER HISTORY
  // ==========================================

  /// Fetch user's order history from backend
  static Future<Map<String, dynamic>> fetchOrders() async {
    try {
      initInterceptors();
      final response = await _dio.get('/auth/orders');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch orders.');
    }
  }

  /// Place an order from the cart
  static Future<Map<String, dynamic>> placeOrder(
    String paymentMethod, {
    required Map<String, dynamic> deliveryAddress,
    String? couponCode,
    String? razorpayOrderId,
    String? razorpayPaymentId,
  }) async {
    try {
      initInterceptors();
      final response = await _dio.post(
        '/orders/place',
        data: {
          'paymentMethod': paymentMethod,
          'deliveryAddress': deliveryAddress,
          if (couponCode != null && couponCode.isNotEmpty)
            'couponCode': couponCode,
          if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
          if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to place order.');
    }
  }

  /// Save / update the user's delivery address on the backend
  static Future<Map<String, dynamic>> saveAddress({
    required String houseNo,
    String floor = '',
    String building = '',
    String area = '',
    String landmark = '',
    required String city,
    String state = '',
    required String pincode,
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    try {
      initInterceptors();
      final response = await _dio.post(
        '/auth/address',
        data: {
          'houseNo': houseNo,
          'floor': floor,
          'building': building,
          'area': area,
          'landmark': landmark,
          'city': city,
          'state': state,
          'pincode': pincode,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to save address.');
    }
  }

  /// Fetch all saved addresses for the user from Address collection
  static Future<List<Map<String, dynamic>>> fetchSavedAddresses() async {
    try {
      initInterceptors();
      final response = await _dio.get('/auth/addresses');
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          response.data['addresses'] ?? [],
        );
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch addresses.',
      );
    }
  }

  /// Add or update a saved address in the Address collection
  static Future<Map<String, dynamic>> addSavedAddress({
    required String houseNo,
    String floor = '',
    String building = '',
    String area = '',
    String landmark = '',
    required String city,
    String state = '',
    required String pincode,
    String addressType = 'home',
    String? addressId,
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    try {
      initInterceptors();
      final response = await _dio.post(
        '/auth/addresses',
        data: {
          'houseNo': houseNo,
          'floor': floor,
          'building': building,
          'area': area,
          'landmark': landmark,
          'city': city,
          'state': state,
          'pincode': pincode,
          'addressType': addressType,
          if (addressId != null) 'addressId': addressId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to save address.');
    }
  }

  // ==========================================
  // PAYMENT API
  // ==========================================

  /// Create Razorpay Order
  static Future<Map<String, dynamic>> createRazorpayOrder(double amount) async {
    try {
      initInterceptors();
      final response = await _dio.post(
        '/payment/create-order',
        data: {'amount': amount},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create payment order.',
      );
    }
  }

  /// Verify Razorpay Payment Signature
  static Future<Map<String, dynamic>> verifyRazorpayPayment(
    String orderId,
    String paymentId,
    String signature,
  ) async {
    try {
      initInterceptors();
      final response = await _dio.post(
        '/payment/verify-payment',
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to verify payment.',
      );
    }
  }

  // ==========================================
  // BANNERS
  // ==========================================

  /// Fetch active banners from backend (replaces mock)
  static Future<List<Map<String, dynamic>>> fetchDynamicBanners() async {
    final response = await _dio.get('/banners');
    if (response.data['success'] == true) {
      return List<Map<String, dynamic>>.from(response.data['banners'] ?? []);
    }
    return [];
  }

  // ==========================================
  // COUPONS
  // ==========================================

  /// Fetch all active (non-expired) coupons
  static Future<List<Map<String, dynamic>>> fetchActiveCoupons() async {
    try {
      final response = await _dio.get('/coupons');
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['coupons'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch coupons: $e");
      return [];
    }
  }

  /// Validate a coupon code against a subtotal — returns discount amount
  static Future<Map<String, dynamic>> validateCoupon(
    String code,
    double subtotal,
  ) async {
    try {
      final response = await _dio.post(
        '/coupons/validate',
        data: {'code': code, 'subtotal': subtotal},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Invalid coupon.');
    }
  }

  // ==========================================
  // REVIEWS
  // ==========================================

  /// Fetch all reviews for a product
  static Future<List<Map<String, dynamic>>> fetchProductReviews(
    String productId,
  ) async {
    try {
      final response = await _dio.get('/reviews/product/$productId');
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['reviews'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch reviews: $e");
      return [];
    }
  }

  /// Check if the logged-in user can review a product
  static Future<Map<String, dynamic>> canReviewProduct(String productId) async {
    try {
      initInterceptors();
      final response = await _dio.get('/reviews/can-review/$productId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to check review eligibility.',
      );
    }
  }

  /// Post a review for a product
  static Future<Map<String, dynamic>> postReview({
    required String productId,
    required String vendorId,
    required int rating,
    String reviewText = '',
  }) async {
    try {
      initInterceptors();
      final response = await _dio.post(
        '/reviews',
        data: {
          'productId': productId,
          'vendorId': vendorId,
          'rating': rating,
          'reviewText': reviewText,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to post review.');
    }
  }

  /// Fetch app settings (delivery charge, tax %, min order, etc.)
  static Future<Map<String, dynamic>> fetchSettings() async {
    try {
      final response = await _dio.get('/settings');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch settings.',
      );
    }
  }

  /// Fetch all active offers
  static Future<List<Offer>> fetchOffers() async {
    try {
      final response = await _dio.get('/offers');
      if (response.data['success'] == true) {
        final list = response.data['offers'] as List<dynamic>? ?? [];
        return list
            .map(
              (j) => Offer.fromJson(
                j as Map<String, dynamic>,
                imageBaseUrl: imageBaseUrl,
              ),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch offers.');
    }
  }

  /// Legacy single-offer endpoint (kept for backward compat)
  static Future<Map<String, dynamic>> fetchSpecialOffer() async {
    try {
      final response = await _dio.get('/offers/special');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch special offer.',
      );
    }
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================

  /// Fetch user notifications from backend
  static Future<Map<String, dynamic>> fetchNotifications() async {
    try {
      initInterceptors();
      final response = await _dio.get('/auth/notifications');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch notifications.',
      );
    }
  }

  /// Mark a single notification as read
  static Future<Map<String, dynamic>> markNotificationRead(String id) async {
    try {
      initInterceptors();
      final response = await _dio.put('/auth/notifications/$id/read');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to mark notification.',
      );
    }
  }

  /// Mark all notifications as read
  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    try {
      initInterceptors();
      final response = await _dio.put('/auth/notifications/read-all');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to mark all notifications.',
      );
    }
  }
}
