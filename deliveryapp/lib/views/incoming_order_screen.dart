import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers/delivery_controller.dart';
import '../core/models/order_model.dart';
import '../core/theme/app_theme.dart';
import '../services/push_notification_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// Shown as a full-screen alert when a new order is available nearby.
/// Auto-dismisses after 30 seconds if not accepted.
class IncomingOrderScreen extends StatefulWidget {
  const IncomingOrderScreen({super.key});
  @override
  State<IncomingOrderScreen> createState() => _IncomingOrderScreenState();
}

class _IncomingOrderScreenState extends State<IncomingOrderScreen> with SingleTickerProviderStateMixin {
  late final DeliveryOrder order;
  late final DeliveryController dc;
  late AnimationController _anim;
  Timer? _timer;
  int _countdown = 30;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    order = Get.arguments as DeliveryOrder;
    dc = Get.find<DeliveryController>();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 30))..forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() => _countdown--);
      }
    });

    // Cancel any OS-level notifications and play sound locally
    PushNotificationService.cancelAllNotifications();
    _playAlertSound();
  }

  Future<void> _playAlertSound() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('order_sound.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 20),
            // Pulsing icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 600),
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                child: const Icon(Icons.delivery_dining_rounded, color: AppTheme.primary, size: 56),
              ),
            ),
            const SizedBox(height: 20),
            Text('New Order Nearby!', style: TextStyle(color: AppTheme.textColor, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Accept within $_countdown seconds', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 8),
            // Countdown bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => LinearProgressIndicator(
                  value: 1 - _anim.value,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(
                    _countdown > 15 ? AppTheme.primary : _countdown > 8 ? Colors.orange : Colors.red,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Order details card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(order.shortId, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text('₹${order.deliveryCharge.toStringAsFixed(0)} earning', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _row(Icons.storefront_rounded, Colors.orange, 'Pickup', order.vendorName, order.vendorAddress),
                  const SizedBox(height: 12),
                  _row(Icons.location_on_rounded, Colors.redAccent, 'Deliver to', order.customerName, order.deliveryAddress),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _chip('${order.items.length} item${order.items.length == 1 ? '' : 's'}', Icons.shopping_bag_rounded, Colors.blue),
                    _chip('₹${order.totalAmount.toStringAsFixed(0)}', Icons.currency_rupee_rounded, Colors.green),
                    _chip(order.paymentMethod.toUpperCase(), Icons.payment_rounded, Colors.purple),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // Accept / Decline buttons
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    dc.declinedOrderIds.add(order.id);
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Decline', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Obx(() => ElevatedButton(
                  onPressed: dc.isLoading.value ? null : () async {
                    Navigator.of(context).pop();
                    await dc.acceptOrder(order.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: dc.isLoading.value
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Accept Order 🛵', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                )),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _row(IconData icon, Color color, String title, String name, String addr) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        Text(name, style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
        if (addr.isNotEmpty) Text(addr, style: TextStyle(color: AppTheme.textMuted, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }
}
