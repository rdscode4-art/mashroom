import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/core/controllers/profile_controller.dart';
import 'package:organic_grow/core/controllers/order_controller.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// A single saved address entry
class SavedAddress {
  final String? id;
  final String houseNo;
  final String floor;
  final String building;
  final String area;
  final String landmark;
  final String fullAddress;
  final String city;
  final String state;
  final String pincode;
  final String addressType;
  final double latitude;
  final double longitude;

  const SavedAddress({
    this.id,
    required this.houseNo,
    this.floor = '',
    this.building = '',
    this.area = '',
    this.landmark = '',
    required this.fullAddress,
    required this.city,
    this.state = '',
    required this.pincode,
    this.addressType = 'home',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
        id: j['_id'] as String?,
        houseNo: j['houseNo'] ?? '',
        floor: j['floor'] ?? '',
        building: j['building'] ?? '',
        area: j['area'] ?? '',
        landmark: j['landmark'] ?? '',
        fullAddress: j['fullAddress'] ?? '',
        city: j['city'] ?? '',
        state: j['state'] ?? '',
        pincode: j['pincode'] ?? '',
        addressType: j['addressType'] ?? 'home',
        latitude: (j['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0.0,
      );

  /// Short one-liner for the pinned bar
  String get shortLine {
    final parts = <String>[];
    if (houseNo.isNotEmpty) parts.add(houseNo);
    if (building.isNotEmpty) parts.add(building);
    if (area.isNotEmpty) parts.add(area);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(', ');
  }

  /// Second line (city, state, pincode)
  String get subLine {
    final parts = <String>[];
    if (state.isNotEmpty) parts.add(state);
    if (pincode.isNotEmpty) parts.add(pincode);
    return parts.join(' – ');
  }

  IconData get icon {
    switch (addressType) {
      case 'work':
        return Icons.work_rounded;
      case 'other':
        return Icons.location_on_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  Map<String, dynamic> toOrderPayload() => {
        'fullAddress': fullAddress,
        'city': city,
        'state': state,
        'pincode': pincode,
        'landmark': landmark,
        'houseNo': houseNo,
        'floor': floor,
        'building': building,
        'area': area,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class CheckoutController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────
  var selectedPaymentMethod = 'cod'.obs;
  var isPlacingOrder = false.obs;
  var isSavingAddress = false.obs;
  var isLoadingAddresses = false.obs;

  // Dynamic charges from backend Settings
  var deliveryCharge = 30.0.obs;
  var taxPercent = 5.0.obs;

  // Coupon state
  var couponCode = ''.obs;
  var couponDiscount = 0.0.obs;
  var couponMessage = ''.obs;
  var isValidatingCoupon = false.obs;
  var couponApplied = false.obs;

  double get subtotal => Get.find<CartController>().totalAmount.value;
  double get tax => subtotal * (taxPercent.value / 100);
  double get grandTotal => subtotal + deliveryCharge.value + tax - couponDiscount.value;

  /// All saved addresses fetched from backend
  var savedAddresses = <SavedAddress>[].obs;

  /// Index into [savedAddresses] that is currently selected (-1 = none)
  var selectedIndex = (-1).obs;

  SavedAddress? get selectedAddress =>
      (selectedIndex.value >= 0 && selectedIndex.value < savedAddresses.length)
          ? savedAddresses[selectedIndex.value]
          : null;

  bool get hasAddress => selectedAddress != null;

  final CartController cartController = Get.find();

  late Razorpay _razorpay;
  String _currentRazorpayOrderId = '';

  // ── Lifecycle ──────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _loadAddresses();
    
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiService.fetchSettings();
      if (res['success'] == true && res['settings'] != null) {
        final s = res['settings'] as Map<String, dynamic>;
        deliveryCharge.value = (s['deliveryCharge'] as num?)?.toDouble() ?? 30.0;
        taxPercent.value = (s['taxPercent'] as num?)?.toDouble() ?? 5.0;
      }
    } catch (_) {
      // keep defaults
    }
  }

  /// Fetch saved addresses, auto-select the most recent one
  Future<void> _loadAddresses() async {
    try {
      isLoadingAddresses.value = true;
      final list = await ApiService.fetchSavedAddresses();
      savedAddresses.assignAll(list.map(SavedAddress.fromJson));
      // Auto-select the first (most recent) address
      if (savedAddresses.isNotEmpty) {
        selectedIndex.value = 0;
      } else {
        // Fall back to profile address if no saved addresses yet
        _tryPrefillFromProfile();
      }
    } catch (_) {
      _tryPrefillFromProfile();
    } finally {
      isLoadingAddresses.value = false;
    }
  }

  void _tryPrefillFromProfile() {
    try {
      final p = Get.find<ProfileController>();
      if (p.savedHouseNo.value.isNotEmpty) {
        final addr = SavedAddress(
          houseNo: p.savedHouseNo.value,
          floor: p.savedFloor.value,
          building: p.savedBuilding.value,
          area: p.savedArea.value,
          landmark: p.savedLandmark.value,
          fullAddress: p.user.value.address,
          city: p.savedCity.value,
          state: p.savedState.value,
          pincode: p.savedPincode.value,
        );
        savedAddresses.insert(0, addr);
        selectedIndex.value = 0;
      }
    } catch (_) {}
  }

  void selectAddress(int index) {
    selectedIndex.value = index;
  }

  void setPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  Future<void> applyCoupon(String code) async {
    if (code.trim().isEmpty) return;
    try {
      isValidatingCoupon.value = true;
      couponMessage.value = '';
      final res = await ApiService.validateCoupon(code.trim(), subtotal);
      if (res['success'] == true) {
        final c = res['coupon'] as Map<String, dynamic>;
        couponCode.value = c['code'] as String;
        couponDiscount.value = (c['discountAmount'] as num).toDouble();
        couponApplied.value = true;
        couponMessage.value = res['message'] as String;
      }
    } catch (e) {
      couponApplied.value = false;
      couponDiscount.value = 0;
      couponMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isValidatingCoupon.value = false;
    }
  }

  void removeCoupon() {
    couponCode.value = '';
    couponDiscount.value = 0.0;
    couponMessage.value = '';
    couponApplied.value = false;
  }

  /// Save a new address (or update existing) and reload the list
  Future<bool> saveNewAddress({
    required String houseNo,
    required String floor,
    required String building,
    required String area,
    required String landmark,
    required String city,
    required String state,
    required String pincode,
    required String addressType,
    double latitude = 0.0,
    double longitude = 0.0,
    String? addressId,
  }) async {
    if (houseNo.trim().isEmpty) {
      _snack('Required', 'Please enter your house / flat number.', Colors.orange);
      return false;
    }
    if (city.trim().isEmpty) {
      _snack('Required', 'Please enter your city.', Colors.orange);
      return false;
    }
    if (pincode.trim().isEmpty) {
      _snack('Required', 'Please enter your pincode.', Colors.orange);
      return false;
    }
    try {
      isSavingAddress.value = true;
      final res = await ApiService.addSavedAddress(
        houseNo: houseNo.trim(),
        floor: floor.trim(),
        building: building.trim(),
        area: area.trim(),
        landmark: landmark.trim(),
        city: city.trim(),
        state: state.trim(),
        pincode: pincode.trim(),
        addressType: addressType,
        latitude: latitude,
        longitude: longitude,
        addressId: addressId,
      );
      if (res['success'] == true) {
        await _loadAddresses(); // refresh list and auto-select
        _snack('Saved ✅', 'Address saved successfully', Colors.green);
        return true;
      }
      return false;
    } catch (e) {
      _snack('Error', e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
      return false;
    } finally {
      isSavingAddress.value = false;
    }
  }

  Future<void> placeOrder() async {
    if (cartController.cartItems.isEmpty) {
      _snack('Empty Cart', 'Your cart is empty.', Colors.orange);
      return;
    }
    if (!hasAddress) {
      _snack('Address Required',
          'Please add a delivery address before placing your order.', Colors.orange);
      return;
    }

    if (selectedPaymentMethod.value == 'online') {
      _startOnlinePayment();
    } else {
      _finalizeOrder(null, null);
    }
  }

  Future<void> _startOnlinePayment() async {
    try {
      isPlacingOrder.value = true;
      final res = await ApiService.createRazorpayOrder(grandTotal);
      if (res['success'] == true) {
        _currentRazorpayOrderId = res['orderId'];
        final String keyId = res['key'];
        
        var options = {
          'key': keyId,
          'amount': res['amount'],
          'name': 'RiFresh India',
          'order_id': _currentRazorpayOrderId,
          'description': 'Organic Grocery Purchase',
          'prefill': {
            'contact': Get.find<ProfileController>().user.value.phone,
            'email': Get.find<ProfileController>().user.value.email,
          }
        };

        _razorpay.open(options);
      } else {
        isPlacingOrder.value = false;
        _snack('Payment Error', 'Failed to initialize payment gateway.', Colors.redAccent);
      }
    } catch (e) {
      isPlacingOrder.value = false;
      _snack('Payment Error', e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final res = await ApiService.verifyRazorpayPayment(
        response.orderId!,
        response.paymentId!,
        response.signature!,
      );
      if (res['success'] == true) {
        _finalizeOrder(response.orderId, response.paymentId);
      } else {
        isPlacingOrder.value = false;
        _snack('Verification Failed', 'Payment verification failed on server.', Colors.redAccent);
      }
    } catch (e) {
      isPlacingOrder.value = false;
      _snack('Verification Error', e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isPlacingOrder.value = false;
    _snack('Payment Failed', response.message ?? 'Transaction cancelled or failed.', Colors.redAccent);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    isPlacingOrder.value = false;
    _snack('External Wallet', 'External wallets are currently not supported.', Colors.orange);
  }

  Future<void> _finalizeOrder(String? rzpOrderId, String? rzpPaymentId) async {
    try {
      isPlacingOrder.value = true;
      final response = await ApiService.placeOrder(
        selectedPaymentMethod.value,
        deliveryAddress: selectedAddress!.toOrderPayload(),
        couponCode: couponApplied.value ? couponCode.value : null,
        razorpayOrderId: rzpOrderId,
        razorpayPaymentId: rzpPaymentId,
      );
      if (response['success'] == true) {
        final orderId = response['order'] != null ? response['order']['_id'] : null;
        await cartController.clearCart();
        try {
          if (Get.isRegistered<OrderController>()) {
            Get.find<OrderController>().fetchOrders();
          } else {
            Get.put(OrderController()).fetchOrders();
          }
        } catch (e) {
          debugPrint('Failed to pre-fetch orders: $e');
        }
        Get.offNamed('/order-success', arguments: orderId);
      }
    } catch (e) {
      _snack('Order Failed', e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
    } finally {
      isPlacingOrder.value = false;
    }
  }

  void _snack(String title, String msg, Color bg) {
    Get.snackbar(title, msg,
        backgroundColor: bg,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3));
  }
}
