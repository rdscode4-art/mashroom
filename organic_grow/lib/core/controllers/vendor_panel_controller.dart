import 'package:get/get.dart';
import 'package:organic_grow/core/models/vendor_model.dart';
import 'package:organic_grow/core/services/api_services.dart';

class VendorPanelController extends GetxController {
  var vendor = Rx<Vendor?>(null);
  var stats = {}.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      final response = await ApiService.fetchVendorDashboard();
      if (response != null && response['success'] == true) {
        vendor.value = Vendor.fromJson(response['vendor']);
        stats.value = response['stats'] ?? {};
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load vendor dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleShopStatus() async {
    try {
      final response = await ApiService.toggleShopStatus();
      if (response != null && response['success'] == true) {
        if (vendor.value != null) {
          final updatedVendor = Vendor(
            id: vendor.value!.id,
            shopName: vendor.value!.shopName,
            isOpen: response['isOpen'],
            // Copy other fields
            ownerName: vendor.value!.ownerName,
            phone: vendor.value!.phone,
            shopImage: vendor.value!.shopImage,
            shopBanner: vendor.value!.shopBanner,
            description: vendor.value!.description,
            rating: vendor.value!.rating,
            totalReviews: vendor.value!.totalReviews,
            totalOrders: vendor.value!.totalOrders,
            deliveryTime: vendor.value!.deliveryTime,
            minimumOrder: vendor.value!.minimumOrder,
            deliveryCharge: vendor.value!.deliveryCharge,
            isApproved: vendor.value!.isApproved,
            isOnline: response['isOpen'],
            cuisineTags: vendor.value!.cuisineTags,
            fullAddress: vendor.value!.fullAddress,
            city: vendor.value!.city,
            state: vendor.value!.state,
            pincode: vendor.value!.pincode,
            latitude: vendor.value!.latitude,
            longitude: vendor.value!.longitude,
          );
          vendor.value = updatedVendor;
        }
        Get.snackbar('Success', response['message']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to toggle shop status: $e');
    }
  }
}
