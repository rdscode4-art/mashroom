import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/core/models/order_model.dart';
import 'package:organic_grow/core/services/api_services.dart';

class OrderController extends GetxController {
  var orders = <AppOrder>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await ApiService.fetchOrders();
      if (response['success'] == true) {
        final List<dynamic> raw = response['orders'] ?? [];
        orders.assignAll(raw.map((o) => AppOrder.fromJson(o as Map<String, dynamic>)).toList());
      }
    } catch (e) {
      debugPrint('Failed to fetch orders: $e');
      errorMessage.value = 'Could not load orders. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
