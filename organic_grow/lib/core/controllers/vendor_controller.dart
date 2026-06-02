import 'package:get/get.dart';
import 'package:organic_grow/core/models/vendor_model.dart';
import 'package:organic_grow/core/models/product_model.dart';
import 'package:organic_grow/core/services/api_services.dart';

class VendorController extends GetxController {
  var vendors = <Vendor>[].obs;
  var nearbyVendors = <Vendor>[].obs;
  var selectedVendor = Rx<Vendor?>(null);
  var vendorProducts = <Product>[].obs;
  var isLoading = true.obs;
  var isProductsLoading = true.obs;

  /// Fetch all approved vendors
  Future<void> fetchVendors() async {
    try {
      isLoading.value = true;
      final data = await ApiService.fetchVendors();
      vendors.assignAll(data);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load stores: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch nearby vendors based on user location
  Future<void> fetchNearbyVendors(double lat, double lng, {double radius = 10}) async {
    try {
      isLoading.value = true;
      final data = await ApiService.fetchNearbyVendors(lat, lng, radius: radius);
      nearbyVendors.assignAll(data);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load nearby stores: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch single vendor detail
  Future<void> fetchVendorDetail(String vendorId) async {
    try {
      isLoading.value = true;
      final vendor = await ApiService.fetchVendorById(vendorId);
      selectedVendor.value = vendor;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load store details: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch all products of a specific vendor
  Future<void> fetchVendorProducts(String vendorId) async {
    try {
      isProductsLoading.value = true;
      final data = await ApiService.fetchVendorProducts(vendorId);
      vendorProducts.assignAll(data);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load products: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProductsLoading.value = false;
    }
  }

  /// Load vendor detail + products together (for store page)
  Future<void> loadVendorStore(String vendorId) async {
    await Future.wait([
      fetchVendorDetail(vendorId),
      fetchVendorProducts(vendorId),
    ]);
  }
}
