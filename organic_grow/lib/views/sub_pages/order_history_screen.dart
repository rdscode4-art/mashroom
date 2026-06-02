import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/order_controller.dart';
import 'package:organic_grow/core/models/order_model.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OrderController orderController = Get.isRegistered<OrderController>()
        ? Get.find<OrderController>()
        : Get.put(OrderController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Orders',
            style: AppTypography.h3
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => orderController.fetchOrders(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (orderController.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor));
        }
        if (orderController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(orderController.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                      color: AppColor.textColor.withValues(alpha: 0.6))),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => orderController.fetchOrders(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                    foregroundColor: Colors.white),
              ),
            ]),
          );
        }
        if (orderController.orders.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long_rounded,
                  size: 80,
                  color: AppColor.primaryColor.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('No orders yet!',
                  style: AppTypography.h3.copyWith(
                      color: AppColor.textColor.withValues(alpha: 0.4))),
              const SizedBox(height: 8),
              Text('Your order history will appear here.',
                  style: AppTypography.bodyMedium.copyWith(
                      color: AppColor.textColor.withValues(alpha: 0.4))),
            ]),
          );
        }
        return RefreshIndicator(
          color: AppColor.primaryColor,
          onRefresh: () => orderController.fetchOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: orderController.orders.length,
            itemBuilder: (context, index) =>
                _OrderCard(order: orderController.orders[index]),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER CARD — expandable, shows each product with Rate button on delivered
// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order});
  final AppOrder order;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  Color _statusColor(String s) {
    switch (s) {
      case 'delivered':        return Colors.green;
      case 'cancelled':        return Colors.redAccent;
      case 'out_for_delivery': return Colors.blue;
      case 'ready_for_pickup': return Colors.indigo;
      case 'packed':           return Colors.orange;
      case 'accepted':         return Colors.teal;
      default:                 return Colors.amber;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'out_for_delivery': return 'Out for Delivery';
      case 'ready_for_pickup': return 'Ready for Pickup 🛵';
      case 'delivered':        return 'Delivered ✓';
      case 'cancelled':        return 'Cancelled';
      case 'packed':           return 'Packed';
      case 'accepted':         return 'Accepted';
      default:                 return 'Pending';
    }
  }

  String _formatDate(DateTime dt) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final color = _statusColor(order.orderStatus);
    final label = _statusLabel(order.orderStatus);
    final isDelivered = order.orderStatus == 'delivered';
    final shortId = '#${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        // ── Header (always visible) ──────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(shortId,
                        style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColor.textColor)),
                    const SizedBox(height: 2),
                    Text(order.vendorName,
                        style: AppTypography.caption.copyWith(
                            color: AppColor.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ]),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(label,
                          style: AppTypography.caption.copyWith(
                              color: color, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColor.textColor.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              // Summary row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                      label: 'Date', value: _formatDate(order.createdAt)),
                  _InfoChip(
                      label: 'Items',
                      value: '${order.totalItemCount} item${order.totalItemCount == 1 ? '' : 's'}'),
                  _InfoChip(
                      label: 'Total',
                      value: '₹${order.totalAmount.toStringAsFixed(0)}',
                      valueColor: AppColor.primaryColor),
                ],
              ),
            ]),
          ),
        ),

        // ── Expanded product list ────────────────────────────────────
        if (_expanded) ...[
          Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
              indent: 16,
              endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Products in this order',
                    style: AppTypography.caption.copyWith(
                        color: AppColor.textColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                ...order.items.map((item) => _ProductRow(
                      item: item,
                      vendorId: order.vendorId,
                      isDelivered: isDelivered,
                    )),
              ],
            ),
          ),

          // Payment info strip & Track button
          Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
              indent: 16,
              endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _PayBadge(
                      label: order.paymentMethod == 'cod'
                          ? 'COD'
                          : 'Online',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _PayBadge(
                      label: order.paymentStatus == 'paid'
                          ? 'Paid ✓'
                          : 'Payment Pending',
                      color: order.paymentStatus == 'paid'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),
                if (order.orderStatus != 'delivered' && order.orderStatus != 'cancelled') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/track-order', arguments: order.id),
                      icon: const Icon(Icons.gps_fixed_rounded, size: 15),
                      label: const Text('Track Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: AppTypography.buttonMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT ROW — shows product image, name, price + Rate button if delivered
// ─────────────────────────────────────────────────────────────────────────────
class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.item,
    required this.vendorId,
    required this.isDelivered,
  });

  final OrderItem item;
  final String vendorId;
  final bool isDelivered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Product image
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.productImage.isNotEmpty
              ? Image.network(
                  item.productImage,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgFallback(),
                )
              : _imgFallback(),
        ),
        const SizedBox(width: 12),

        // Name + price
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: AppColor.textColor)),
            const SizedBox(height: 3),
            Text(
              '${item.unit} × ${item.quantity}  •  ₹${(item.price * item.quantity).toStringAsFixed(0)}',
              style: AppTypography.caption.copyWith(
                  color: AppColor.textColor.withValues(alpha: 0.55)),
            ),
          ]),
        ),

        // Rate button — only for delivered orders
        if (isDelivered) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Get.toNamed('/write-review', arguments: {
              'productId': item.productId,
              'vendorId': vendorId,
              'productName': item.productName,
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                const SizedBox(width: 4),
                Text('Rate',
                    style: AppTypography.caption.copyWith(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _imgFallback() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColor.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.eco_rounded,
            color: AppColor.primaryColor, size: 24),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, this.valueColor});
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTypography.caption.copyWith(
              color: AppColor.textColor.withValues(alpha: 0.4))),
      const SizedBox(height: 3),
      Text(value,
          style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColor.textColor)),
    ]);
  }
}

class _PayBadge extends StatelessWidget {
  const _PayBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: AppTypography.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
