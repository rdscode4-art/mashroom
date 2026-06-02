import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:organic_grow/core/models/banner_model.dart';
import 'package:organic_grow/core/models/category_model.dart';
import 'package:organic_grow/core/models/product_model.dart';
import 'package:organic_grow/core/models/vendor_model.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:organic_grow/core/controllers/profile_controller.dart';
import 'package:organic_grow/core/controllers/connectivity_controller.dart';

class HomeController extends GetxController {
  var categories = <Category>[].obs;
  var featuredProducts = <Product>[].obs;
  var vendors = <Vendor>[].obs;
  var banners = <BannerItem>[].obs;
  var currentCarouselIndex = 0.obs;
  var isLoading = true.obs;
  var isRefreshing = false.obs;

  final ConnectivityController connectivityController = Get.find<ConnectivityController>();
  late final ProfileController profileController;

  // Zomato filter option: '', 'nearest', 'rating', 'open'
  var selectedFilter = ''.obs;

  List<Vendor> get filteredVendors {
    var list = List<Vendor>.from(vendors);
    if (selectedFilter.value == 'nearest') {
      list.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });
    } else if (selectedFilter.value == 'rating') {
      list = list.where((v) => v.rating >= 4.0).toList();
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (selectedFilter.value == 'open') {
      list = list.where((v) => v.isOpen).toList();
    }
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    // Worker to automatically fetch hyperlocal home data when coordinates are updated
    ever(profileController.latitude, (double lat) {
      if (lat != 0.0) {
        fetchHomeData();
      }
    });

    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    try {
      await connectivityController.checkConnection();
      if (!connectivityController.isConnected) {
        isLoading.value = false;
        isRefreshing.value = false;
        Get.snackbar("No Internet", "Please check your connection and try again",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      isLoading.value = true;

      final categoriesData = await ApiService.fetchCategories();

      // Fetch banners from backend — fall back to assets if API fails or returns none
      List<BannerItem> bannersData;
      try {
        final bannersRaw = await ApiService.fetchDynamicBanners();
        if (bannersRaw.isNotEmpty) {
          bannersData = bannersRaw
              .map((b) => BannerItem.fromJson(b, ApiService.imageBaseUrl))
              .where((b) => b.imageUrl.isNotEmpty)
              .toList();
        } else {
          bannersData = _staticFallbackBanners();
        }
      } catch (e) {
        debugPrint('⚠️ Banner fetch failed: $e — using static fallback');
        bannersData = _staticFallbackBanners();
      }

      final lat = profileController.latitude.value;
      final lng = profileController.longitude.value;

      List<Product> productsData;
      List<Vendor> vendorsData;

      if (lat != 0.0 && lng != 0.0) {
        productsData = await ApiService.fetchFeaturedProducts(lat: lat, lng: lng);
        vendorsData = await ApiService.fetchNearbyVendors(lat, lng);
      } else {
        productsData = await ApiService.fetchFeaturedProducts();
        vendorsData = await ApiService.fetchVendors();
      }

      categories.assignAll(categoriesData);
      featuredProducts.assignAll(productsData);
      vendors.assignAll(vendorsData);
      banners.assignAll(bannersData);

      isLoading.value = false;
      isRefreshing.value = false;
    } catch (e) {
      isLoading.value = false;
      isRefreshing.value = false;
      Get.snackbar('Error', 'Failed to load data: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    if (ApiService.userToken != null) {
      await profileController.fetchUserProfile();
      await profileController.fetchAndSaveCurrentLocation();
    } else {
      await fetchHomeData();
    }
  }

  void updateCarouselIndex(int index) {
    currentCarouselIndex.value = index;
  }

  List<BannerItem> _staticFallbackBanners() => [
        const BannerItem(id: 'f1', imageUrl: 'assets/banner_images/banner1.jpg'),
        const BannerItem(id: 'f2', imageUrl: 'assets/banner_images/banner2.png'),
        const BannerItem(id: 'f3', imageUrl: 'assets/banner_images/banner3.png'),
      ];
}
