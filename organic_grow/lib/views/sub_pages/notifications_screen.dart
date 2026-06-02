import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/notification_controller.dart';
import 'package:organic_grow/core/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController notifController =
        Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : Get.put(NotificationController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notifications',
            style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        actions: [
          Obx(() {
            final hasUnread = notifController.notifications.any((n) => !n.isRead);
            if (!hasUnread) return const SizedBox.shrink();
            return TextButton(
              onPressed: () => notifController.markAllAsRead(),
              child: Text('Mark all read',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  )),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (notifController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColor.primaryColor),
          );
        }

        if (notifController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(notifController.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColor.textColor.withOpacity(0.6))),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => notifController.fetchNotifications(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor, foregroundColor: Colors.white),
                ),
              ],
            ),
          );
        }

        if (notifController.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 80, color: AppColor.primaryColor.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No notifications yet!',
                    style: AppTypography.h3
                        .copyWith(color: AppColor.textColor.withOpacity(0.4))),
                const SizedBox(height: 8),
                Text('You\'ll be notified about orders and offers.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColor.textColor.withOpacity(0.4))),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColor.primaryColor,
          onRefresh: () => notifController.fetchNotifications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: notifController.notifications.length,
            itemBuilder: (context, index) {
              return _NotifCard(
                notif: notifController.notifications[index],
                onTap: () => notifController.markAsRead(
                    notifController.notifications[index].id),
              );
            },
          ),
        );
      }),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;

  const _NotifCard({required this.notif, required this.onTap});

  IconData _iconForType(String type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping_rounded;
      case 'promo':
      case 'offer':
        return Icons.local_offer_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'points':
        return Icons.star_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'order':
        return Colors.green;
      case 'promo':
      case 'offer':
        return Colors.amber;
      case 'payment':
        return Colors.blue;
      case 'points':
        return Colors.purple;
      default:
        return AppColor.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(notif.type);
    final icon = _iconForType(notif.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Theme.of(context).cardColor
              : AppColor.primaryColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notif.isRead
                ? Theme.of(context).dividerColor
                : AppColor.primaryColor.withOpacity(0.3),
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight:
                                  notif.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: AppColor.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notif.timeAgo,
                          style: AppTypography.caption
                              .copyWith(color: AppColor.textColor.withOpacity(0.4)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.body,
                      style: AppTypography.bodyMedium.copyWith(
                          color: AppColor.textColor.withOpacity(0.6)),
                    ),
                    if (!notif.isRead) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColor.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('New',
                              style: AppTypography.caption.copyWith(
                                  color: AppColor.primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
