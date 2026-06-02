import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/core/models/notification_model.dart';
import 'package:organic_grow/core/services/api_services.dart';

class NotificationController extends GetxController {
  var notifications = <AppNotification>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await ApiService.fetchNotifications();
      if (response['success'] == true) {
        final List<dynamic> raw = response['notifications'] ?? [];
        notifications.assignAll(
          raw.map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
      errorMessage.value = 'Could not load notifications. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiService.markNotificationRead(id);
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        notifications[idx].isRead = true;
        notifications.refresh(); // Trigger Obx rebuild
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      for (final n in notifications) {
        n.isRead = true;
      }
      notifications.refresh();
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
    }
  }
}
