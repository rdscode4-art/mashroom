import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';

class DeliveryController extends GetxController {
  var isOnline = false.obs;
  var isAvailable = true.obs;
  var assignedOrder = Rxn<DeliveryOrder>();
  var orderHistory = <DeliveryOrder>[].obs;
  var isLoading = false.obs;
  var totalDeliveries = 0.obs;
  var totalEarnings = 0.0.obs;
  var todayDeliveries = 0.obs;
  var declinedOrderIds = <String>{}.obs;

  // Polling timer — checks for new assigned orders every 5s when online
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    _loadDashboard();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadDashboard() async {
    try {
      isLoading.value = true;
      final res = await ApiService.getDashboard();
      if (res['success'] == true) {
        final p = res['partner'] as Map<String, dynamic>;
        final s = res['stats'] as Map<String, dynamic>;
        isOnline.value = p['isOnline'] ?? false;
        isAvailable.value = p['isAvailable'] ?? true;
        totalDeliveries.value = (s['totalDeliveries'] as num?)?.toInt() ?? 0;
        totalEarnings.value = (s['totalEarnings'] as num?)?.toDouble() ?? 0;
        todayDeliveries.value = (s['todayDeliveries'] as num?)?.toInt() ?? 0;

        // If not available, there's an active order — fetch it
        if (isOnline.value) {
          await _updateLocationLoop();
          await fetchAssignedOrder();
          _startPolling();
        }
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAssignedOrder() async {
    try {
      final res = await ApiService.getAssignedOrder();
      if (res['success'] == true && res['order'] != null) {
        assignedOrder.value = DeliveryOrder.fromJson(res['order'] as Map<String, dynamic>);
      } else {
        assignedOrder.value = null;
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!isOnline.value) { _pollTimer?.cancel(); return; }
      await fetchAssignedOrder();
      // If we got an order and we're still "available" (not yet accepted), show it
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> toggleOnline() async {
    try {
      final res = await ApiService.toggleOnline();
      if (res['success'] == true) {
        isOnline.value = res['isOnline'] ?? !isOnline.value;
        if (isOnline.value) {
          await _updateLocationLoop();
          await fetchAssignedOrder();
          _startPolling();
          Get.snackbar('You are Online 🟢', 'You will receive delivery requests',
              backgroundColor: Colors.green, colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
        } else {
          _stopPolling();
          assignedOrder.value = null;
          declinedOrderIds.clear();
          Get.snackbar('You are Offline 🔴', 'You will not receive requests',
              backgroundColor: Colors.grey[700], colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
        }
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _updateLocationLoop() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await ApiService.updateLocation(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      isLoading.value = true;
      final res = await ApiService.acceptOrder(orderId);
      if (res['success'] == true) {
        isAvailable.value = false;
        assignedOrder.value = DeliveryOrder.fromJson(res['order'] as Map<String, dynamic>);
        Get.snackbar('Order Accepted! 🛵', 'Head to the vendor for pickup',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
      } else {
        // Another rider accepted first
        assignedOrder.value = null;
        Get.snackbar('Too Late!', res['message'] ?? 'Order taken by another rider',
            backgroundColor: Colors.orange, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmPickup(String orderId, String otp) async {
    try {
      isLoading.value = true;
      final res = await ApiService.confirmPickup(orderId, otp);
      if (res['success'] == true) {
        assignedOrder.value = DeliveryOrder.fromJson(res['order'] as Map<String, dynamic>);
        Get.snackbar('Picked Up! 🚴', 'Head to the customer now',
            backgroundColor: Colors.blue, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
      }
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markDelivered(String orderId, String otp) async {
    try {
      isLoading.value = true;
      final res = await ApiService.markDelivered(orderId, otp);
      if (res['success'] == true) {
        assignedOrder.value = null;
        isAvailable.value = true;
        totalDeliveries.value++;
        todayDeliveries.value++;
        await _loadDashboard();
        Get.snackbar('Delivered! ✅', 'Great job! Keep it up.',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
      }
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.redAccent, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHistory() async {
    try {
      final res = await ApiService.getOrderHistory();
      if (res['success'] == true) {
        final list = res['orders'] as List<dynamic>? ?? [];
        orderHistory.assignAll(list.map((o) => DeliveryOrder.fromJson(o as Map<String, dynamic>)));
      }
    } catch (_) {}
  }

  Future<void> refresh() => _loadDashboard();
}
