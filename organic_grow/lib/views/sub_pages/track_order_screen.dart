import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/order_controller.dart';
import 'package:organic_grow/core/models/order_model.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  late final OrderController orderController;
  late final String orderId;
  Timer? _refreshTimer;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    try {
      orderController = Get.find<OrderController>();
    } catch (_) {
      orderController = Get.put(OrderController());
    }
    orderId = Get.arguments as String;

    // Refresh immediately on load, then poll every 10 seconds
    orderController.fetchOrders();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      orderController.fetchOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Get.snackbar(
          'Error',
          'Could not place a call to $phoneNumber',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Failed to call phone number: $e');
    }
  }

  double _getProgressFraction(String status) {
    switch (status) {
      case 'pending':
        return 0.05;
      case 'accepted':
        return 0.20;
      case 'packed':
        return 0.40;
      case 'ready_for_pickup':
        return 0.60;
      case 'out_for_delivery':
        return 0.80;
      case 'delivered':
        return 1.00;
      default:
        return 0.05;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'accepted':
        return 'Order Accepted';
      case 'packed':
        return 'Packed & Ready';
      case 'ready_for_pickup':
        return 'Rider Arriving';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Processing';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'We have received your order and are waiting for vendor approval.';
      case 'accepted':
        return 'The vendor has accepted your order and is preparing the items.';
      case 'packed':
        return 'Your items have been packed securely and are waiting for the rider.';
      case 'ready_for_pickup':
        return 'Rider has reached the store and is picking up your order.';
      case 'out_for_delivery':
        return 'Your rider is on the way. Keep your phone handy!';
      case 'delivered':
        return 'Order delivered successfully. Enjoy your fresh products!';
      default:
        return 'We are processing your order step-by-step.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final order = orderController.orders.firstWhereOrNull((o) => o.id == orderId);

        if (order == null) {
          if (orderController.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('Track Order'),
              backgroundColor: AppColor.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Order not found', style: AppTypography.h3),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => orderController.fetchOrders(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColor.primaryColor),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final fraction = _getProgressFraction(order.orderStatus);
        final statusTitle = _getStatusTitle(order.orderStatus);
        final statusDesc = _getStatusDescription(order.orderStatus);
        final shortId = order.id.length > 8
            ? order.id.substring(order.id.length - 8).toUpperCase()
            : order.id.toUpperCase();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium Gradient Header AppBar
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              stretch: true,
              elevation: 0,
              backgroundColor: AppColor.primaryColor,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Track Order #$shortId',
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColor.primaryColor, AppColor.btnColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  // 1. Gorgeous Interactive Animated Map Vector Path
                  Container(
                    height: 180,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Map Ambient Background lines
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.05,
                            child: GridPaper(
                              color: AppColor.textColor,
                              interval: 30,
                              divisions: 2,
                              subdivisions: 1,
                            ),
                          ),
                        ),

                        // Vector Bezier Path and Moving Scooter
                        Positioned.fill(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.05, end: fraction),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeInOutCubic,
                            builder: (context, value, child) {
                              return CustomPaint(
                                painter: _BezierRoutePainter(
                                  progress: value,
                                  routeColor: Colors.grey.shade300,
                                  activeColor: AppColor.primaryColor,
                                ),
                              );
                            },
                          ),
                        ),

                        // Shop Marker (Start)
                        Positioned(
                          left: 20,
                          top: 90 - 24,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 6),
                                  ],
                                ),
                                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(height: 4),
                              Text('Store',
                                  style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.textColor.withOpacity(0.6))),
                            ],
                          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms, delay: 1000.ms),
                        ),

                        // Home Marker (End)
                        Positioned(
                          right: 20,
                          top: 90 - 24,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColor.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 6),
                                  ],
                                ),
                                child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(height: 4),
                              Text('Home',
                                  style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.textColor.withOpacity(0.6))),
                            ],
                          ).animate(onPlay: (c) => c.repeat())
.scale(
  duration: 1500.ms,
  begin: const Offset(1, 1),
  end: const Offset(1.05, 1.05),
),
                        ),
                      ],
                    ),
                  ),

                  // 2. Premium OTP Section (if active)
                  if (order.orderOTP != null && order.orderStatus != 'delivered' && order.orderStatus != 'cancelled')
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColor.primaryColor.withOpacity(0.08),
                            AppColor.btnColor.withOpacity(0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColor.primaryColor.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.vpn_key_rounded, color: AppColor.primaryColor, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delivery Verification OTP',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textColor.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    // Big styled digits
                                    ...order.orderOTP!.split('').map((char) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColor.primaryColor.withOpacity(0.2)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        ),
                                        child: Text(
                                          char,
                                          style: AppTypography.h3.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColor.primaryColor,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Share this OTP with the rider to verify delivery.',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColor.textColor.withOpacity(0.55),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Custom styled interactive Copy Button
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: order.orderOTP!));
                              setState(() => _isCopied = true);
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) setState(() => _isCopied = false);
                              });
                              Get.snackbar(
                                'Copied',
                                'OTP Copied to Clipboard!',
                                backgroundColor: AppColor.primaryColor,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isCopied ? Colors.green : AppColor.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isCopied ? Colors.green : AppColor.primaryColor).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Icon(
                                _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  // 3. Dynamic Status Timesteps Display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColor.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.local_shipping_rounded, color: AppColor.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(statusTitle,
                                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    statusDesc,
                                    style: AppTypography.caption.copyWith(
                                        color: AppColor.textColor.withOpacity(0.6), height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(),
                        ),

                        // Timeline steps
                        _buildTimelineStep(
                          title: 'Order Placed',
                          description: 'We have received your order successfully.',
                          isActive: _isStepActive(order.orderStatus, 'pending'),
                          isCompleted: _isStepCompleted(order.orderStatus, 'pending'),
                        ),
                        _buildTimelineStep(
                          title: 'Order Accepted',
                          description: 'The store has accepted and is preparing items.',
                          isActive: _isStepActive(order.orderStatus, 'accepted'),
                          isCompleted: _isStepCompleted(order.orderStatus, 'accepted'),
                        ),
                        _buildTimelineStep(
                          title: 'Packed & Ready',
                          description: 'Order is packed and ready for delivery partner.',
                          isActive: _isStepActive(order.orderStatus, 'packed'),
                          isCompleted: _isStepCompleted(order.orderStatus, 'packed'),
                        ),
                        _buildTimelineStep(
                          title: 'Out for Delivery',
                          description: 'Delivery rider is carrying your fresh package.',
                          isActive: _isStepActive(order.orderStatus, 'out_for_delivery') || _isStepActive(order.orderStatus, 'ready_for_pickup'),
                          isCompleted: _isStepCompleted(order.orderStatus, 'out_for_delivery'),
                        ),
                        _buildTimelineStep(
                          title: 'Delivered',
                          description: 'Order delivered safely to your location.',
                          isActive: _isStepActive(order.orderStatus, 'delivered'),
                          isCompleted: _isStepCompleted(order.orderStatus, 'delivered'),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  // 4. Rider Info Card
                  _buildRiderCard(order),

                  // 5. Vendor Store details card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: order.vendorImage.isNotEmpty
                              ? Image.network(
                                  order.vendorImage,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _storeFallback(),
                                )
                              : _storeFallback(),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.vendorName,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Preparing Store',
                                style: AppTypography.caption.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 6. Order Summary Details Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Summary', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.productName} (${item.unit}) x ${item.quantity}',
                                      style: AppTypography.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Delivery Fee', style: AppTypography.bodySmall.copyWith(color: AppColor.textColor.withOpacity(0.5))),
                            Text('₹${order.deliveryCharge.toStringAsFixed(0)}', style: AppTypography.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                            ),
                            Text(
                              '₹${order.totalAmount.toStringAsFixed(0)}',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w800, color: AppColor.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _storeFallback() => Container(
        width: 50,
        height: 50,
        color: AppColor.primaryColor.withOpacity(0.08),
        child: const Icon(Icons.storefront_rounded, color: AppColor.primaryColor),
      );

  bool _isStepActive(String currentStatus, String targetStatus) {
    return currentStatus == targetStatus;
  }

  bool _isStepCompleted(String currentStatus, String targetStatus) {
    const statuses = ['pending', 'accepted', 'packed', 'ready_for_pickup', 'out_for_delivery', 'delivered'];
    final currentIndex = statuses.indexOf(currentStatus);
    final targetIndex = statuses.indexOf(targetStatus);
    return currentIndex > targetIndex;
  }

  Widget _buildTimelineStep({
    required String title,
    required String description,
    required bool isActive,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Graphic indicators
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColor.primaryColor
                      : (isActive ? Colors.white : Colors.grey.shade200),
                  border: Border.all(
                    color: (isCompleted || isActive) ? AppColor.primaryColor : Colors.grey.shade300,
                    width: isActive ? 5 : 2,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColor.primaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                      : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? AppColor.primaryColor : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Description text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? AppColor.primaryColor
                          : (isCompleted ? AppColor.textColor : AppColor.textColor.withOpacity(0.4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: isActive
                          ? AppColor.textColor.withOpacity(0.8)
                          : AppColor.textColor.withOpacity(isCompleted ? 0.5 : 0.3),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(AppOrder order) {
    // Check if delivery partner is assigned
    if (order.deliveryPartnerName != null && order.deliveryPartnerName!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Rider profile image with fallback
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: order.deliveryPartnerProfileImage != null && order.deliveryPartnerProfileImage!.isNotEmpty
                  ? Image.network(
                      order.deliveryPartnerProfileImage!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _riderFallback(),
                    )
                  : _riderFallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.deliveryPartnerName!,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.deliveryPartnerVehicleNumber ?? 'Delivery Partner',
                    style: AppTypography.caption.copyWith(color: AppColor.textColor.withOpacity(0.5)),
                  ),
                  if (order.deliveryPartnerVehicleType != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Riding ${order.deliveryPartnerVehicleType}',
                      style: AppTypography.caption.copyWith(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (order.deliveryPartnerPhone != null && order.deliveryPartnerPhone!.isNotEmpty)
              IconButton(
                onPressed: () => _makePhoneCall(order.deliveryPartnerPhone!),
                icon: const Icon(Icons.phone_in_talk_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1, end: 0);
    }

    // No rider assigned yet - show elegant pulsing assignment card
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pedal_bike_rounded, color: Colors.amber, size: 24)
                .animate(onPlay: (c) => c.repeat())
                .shake(hz: 3, duration: 1500.ms),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigning Rider...',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Finding the closest delivery partner for your order.',
                  style: AppTypography.caption.copyWith(color: AppColor.textColor.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riderFallback() => Container(
        width: 52,
        height: 52,
        color: AppColor.primaryColor.withOpacity(0.08),
        child: const Icon(Icons.person_rounded, color: AppColor.primaryColor),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BEZIER ROUTE PAINTER — Animates scooter along curved path
// ─────────────────────────────────────────────────────────────────────────────
class _BezierRoutePainter extends CustomPainter {
  final double progress;
  final Color routeColor;
  final Color activeColor;

  _BezierRoutePainter({
    required this.progress,
    required this.routeColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final path = Path();
    path.moveTo(40 + 20, midY); // offset from store icon
    
    // Draw elegant S-curve route path
    path.cubicTo(
      size.width * 0.35, size.height * 0.1,
      size.width * 0.65, size.height * 0.9,
      size.width - 40 - 20, midY, // offset from home icon
    );

    // Draw background road path
    final bgPaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, bgPaint);

    // Draw active path up to progress
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final metrics = path.computeMetrics();
    Offset scooterPos = Offset(40 + 20, midY);
    double scooterAngle = 0;

    for (final metric in metrics) {
      final activePath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(activePath, activePaint);

      final tangent = metric.getTangentForOffset(metric.length * progress);
      if (tangent != null) {
        scooterPos = tangent.position;
        scooterAngle = tangent.angle;
      }
    }

    // Draw Scooter Icon/Marker at progress position
    if (progress > 0.0 && progress < 1.0) {
      canvas.save();
      canvas.translate(scooterPos.dx, scooterPos.dy);
      
      // Draw scooter backing shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(0, 10), 8, shadowPaint);

      // Draw scooter circle badge
      final badgePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, 14, badgePaint);

      // Draw scooter mini icon (scooter drawing)
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '🛵',
          style: TextStyle(fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BezierRoutePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.routeColor != routeColor ||
        oldDelegate.activeColor != activeColor;
  }
}
