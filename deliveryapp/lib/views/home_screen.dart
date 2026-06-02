import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/controllers/auth_controller.dart';
import '../core/controllers/delivery_controller.dart';
import '../core/models/order_model.dart';
import '../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    final dc = Get.isRegistered<DeliveryController>()
        ? Get.find<DeliveryController>()
        : Get.put(DeliveryController());

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: dc.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header ──────────────────────────────────────────
              Row(children: [
                Obx(() {
                  final name = auth.partner.value?.name ?? 'Partner';
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hey, ${name.split(' ').first} 👋',
                        style: TextStyle(color: AppTheme.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Ready to deliver?', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ]);
                }),
                const Spacer(),
              ]),
              const SizedBox(height: 24),

              // ── Online Toggle Card ───────────────────────────────
              Obx(() => _OnlineToggleCard(dc: dc, isOnline: dc.isOnline.value)),
              const SizedBox(height: 20),

              // ── Stats Row ────────────────────────────────────────
              Obx(() => Row(children: [
                _StatCard(label: "Today's Deliveries", value: '${dc.todayDeliveries.value}', icon: Icons.today_rounded, color: Colors.blue),
                const SizedBox(width: 12),
                _StatCard(label: 'Total Deliveries', value: '${dc.totalDeliveries.value}', icon: Icons.check_circle_rounded, color: Colors.green),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Earnings',
                  value: '₹${dc.totalEarnings.value.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee_rounded,
                  color: Colors.amber,
                  onTap: () => Get.toNamed('/wallet'),
                ),
              ])),
              const SizedBox(height: 24),

              // ── Active Order / Incoming Order ────────────────────
              Obx(() {
                final order = dc.assignedOrder.value;
                if (order == null || (dc.isAvailable.value && dc.declinedOrderIds.contains(order.id))) {
                  return dc.isOnline.value
                      ? _WaitingCard()
                      : _OfflineCard();
                }
                
                // If driver is available, this order is just "available" (not yet accepted)
                if (dc.isAvailable.value) {
                  return _AvailableOrderCard(order: order, dc: dc);
                }

                // If driver is not available, it means they have accepted it
                return _ActiveOrderCard(order: order, dc: dc);
              }),
            ]),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Logout', style: TextStyle(color: AppTheme.textColor)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () { Get.back(); auth.logout(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Online Toggle Card ─────────────────────────────────────────────────────
class _OnlineToggleCard extends StatelessWidget {
  const _OnlineToggleCard({required this.dc, required this.isOnline});
  final DeliveryController dc;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dc.toggleOnline,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOnline
                ? [const Color(0xFF1B5E20), AppTheme.primary]
                : [const Color(0xFF1A1A2E), const Color(0xFF2D2D44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isOnline ? AppTheme.primary : Colors.black).withValues(alpha: 0.3),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.delivery_dining_rounded : Icons.power_settings_new_rounded,
              color: Colors.white, size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isOnline ? 'You are Online 🟢' : 'You are Offline 🔴',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                isOnline ? 'Receiving delivery requests' : 'Tap to go online and start earning',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
              ),
            ]),
          ),
          Switch(
            value: isOnline,
            onChanged: (_) => dc.toggleOnline(),
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.3),
          ),
        ]),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: onTap != null
                  ? AppTheme.primary.withOpacity(0.3)
                  : AppTheme.border,
              width: onTap != null ? 1.5 : 1.0,
            ),
            boxShadow: onTap != null
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 10), maxLines: 2),
          ]),
        ),
      ),
    );
  }
}

// ── Waiting Card ───────────────────────────────────────────────────────────
class _WaitingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: [
        const Icon(Icons.hourglass_empty_rounded, color: AppTheme.primary, size: 48),
        const SizedBox(height: 14),
        Text('Waiting for orders...', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text('You\'ll be notified when a new order is available nearby', style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Offline Card ───────────────────────────────────────────────────────────
class _OfflineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: [
        Icon(Icons.wifi_off_rounded, color: AppTheme.textMuted, size: 48),
        const SizedBox(height: 14),
        Text('You are offline', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text('Go online to start receiving delivery requests', style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Active Order Card ──────────────────────────────────────────────────────
class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order, required this.dc});
  final DeliveryOrder order;
  final DeliveryController dc;

  @override
  Widget build(BuildContext context) {
    final isBeforePickup = ['accepted', 'packed', 'ready_for_pickup'].contains(order.orderStatus);
    final isOutForDelivery = order.orderStatus == 'out_for_delivery';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.local_shipping_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              isBeforePickup ? 'Pickup from Vendor' : 'Deliver to Customer',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(order.shortId, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Step indicator
            _StepIndicator(isReadyForPickup: isBeforePickup),
            const SizedBox(height: 16),

            // Vendor info
            _InfoRow(
              icon: Icons.storefront_rounded,
              color: Colors.orange,
              title: 'Pickup from',
              subtitle: order.vendorName,
              detail: order.vendorAddress,
            ),
            const SizedBox(height: 12),

            // Customer info
            _InfoRow(
              icon: Icons.location_on_rounded,
              color: Colors.redAccent,
              title: 'Deliver to',
              subtitle: order.customerName,
              detail: order.deliveryAddress,
              phone: order.customerPhone,
            ),
            const SizedBox(height: 16),

            // Order items
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Items', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.circle, size: 5, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${item.productName} × ${item.quantity} ${item.unit}', style: TextStyle(color: AppTheme.textColor, fontSize: 13))),
                    Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ]),
                )),
                const Divider(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
                  Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
                if (order.paymentMethod == 'cod')
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      const Icon(Icons.money_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('Collect ₹${order.totalAmount.toStringAsFixed(0)} cash on delivery', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 16),

            // Action button
            Obx(() => dc.isLoading.value
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : isBeforePickup
                    ? Column(children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openGoogleNavigation(
                              latitude: order.vendorLat,
                              longitude: order.vendorLng,
                              fallbackQuery: '${order.vendorName}, ${order.vendorAddress}',
                            ),
                            icon: const Icon(Icons.navigation_rounded, color: AppTheme.primary),
                            label: const Text('Navigate to Store', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showPickupOtpDialog(context),
                            icon: const Icon(Icons.check_rounded, color: Colors.white),
                            label: const Text('I\'ve Picked Up the Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ])
                    : isOutForDelivery
                        ? Column(children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openGoogleNavigation(
                                  latitude: order.deliveryLat,
                                  longitude: order.deliveryLng,
                                  fallbackQuery: order.deliveryAddress,
                                ),
                                icon: const Icon(Icons.navigation_rounded, color: AppTheme.primary),
                                label: const Text('Navigate to Customer', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showOtpDialog(context),
                                icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                                label: const Text('Mark as Delivered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ])
                        : const SizedBox.shrink()),
          ]),
        ),
      ]),
    );
  }

  Future<void> _openGoogleNavigation({
    required double latitude,
    required double longitude,
    required String fallbackQuery,
  }) async {
    final hasCoordinates = latitude != 0 && longitude != 0;
    final destination = hasCoordinates
        ? '$latitude,$longitude'
        : Uri.encodeComponent(fallbackQuery.trim());
    if (destination.isEmpty) {
      Get.snackbar('Location Missing', 'Navigation address is not available',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      Get.snackbar('Navigation Failed', 'Could not open Google Maps',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showPickupOtpDialog(BuildContext context) {
    final otpCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Enter Pickup OTP', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Ask the vendor for the 4-digit pickup OTP before collecting the order.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              filled: true, fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              Get.back();
              dc.confirmPickup(order.id, otpCtrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Confirm Pickup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showOtpDialog(BuildContext context) {
    final otpCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Enter Delivery OTP', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Ask the customer for their 4-digit OTP to confirm delivery.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              filled: true, fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              Get.back();
              dc.markDelivered(order.id, otpCtrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.isReadyForPickup});
  final bool isReadyForPickup;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Step(label: 'Accept', done: true),
      _StepLine(active: !isReadyForPickup),
      _Step(label: 'Pickup', done: !isReadyForPickup, active: isReadyForPickup),
      _StepLine(active: false),
      _Step(label: 'Deliver', done: false, active: !isReadyForPickup),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, this.done = false, this.active = false});
  final String label;
  final bool done, active;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppTheme.primary : active ? Colors.orange : AppTheme.border;
    return Column(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        child: Icon(done ? Icons.check_rounded : Icons.circle, color: color, size: 14),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? AppTheme.primary : AppTheme.border,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.color, required this.title, required this.subtitle, required this.detail, this.phone});
  final IconData icon;
  final Color color;
  final String title, subtitle, detail;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          if (detail.isNotEmpty) Text(detail, style: TextStyle(color: AppTheme.textMuted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (phone != null && phone!.isNotEmpty)
            Text(phone!, style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }
}

// ── Available Order Card (Unassigned) ──────────────────────────────────────
class _AvailableOrderCard extends StatelessWidget {
  const _AvailableOrderCard({required this.order, required this.dc});
  final DeliveryOrder order;
  final DeliveryController dc;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Text(
              'New Order Available!',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            Text(order.shortId, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _InfoRow(
              icon: Icons.storefront_rounded, color: Colors.orange,
              title: 'Pickup from', subtitle: order.vendorName, detail: order.vendorAddress,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on_rounded, color: Colors.redAccent,
              title: 'Deliver to', subtitle: order.customerName, detail: order.deliveryAddress,
            ),
            const SizedBox(height: 16),
            Obx(() => dc.isLoading.value
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => dc.acceptOrder(order.id),
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: const Text('Accept Order 🛵', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  )),
          ]),
        ),
      ]),
    );
  }
}

