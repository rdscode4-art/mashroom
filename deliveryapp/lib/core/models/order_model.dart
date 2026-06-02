import '../constants/app_constants.dart';

class DeliveryOrder {
  final String id;
  final String orderStatus;
  final double totalAmount;
  final double deliveryCharge;
  final String paymentMethod;
  final String orderOTP;
  final String customerName;
  final String customerPhone;
  final String vendorName;
  final String vendorPhone;
  final String vendorAddress;
  final double vendorLat;
  final double vendorLng;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final double driverEarning;
  final double deliveryDistance;
  final List<OrderItem> items;
  final DateTime createdAt;

  const DeliveryOrder({
    required this.id,
    required this.orderStatus,
    required this.totalAmount,
    this.deliveryCharge = 0,
    this.paymentMethod = 'cod',
    this.orderOTP = '',
    this.customerName = '',
    this.customerPhone = '',
    this.vendorName = '',
    this.vendorPhone = '',
    this.vendorAddress = '',
    this.vendorLat = 0,
    this.vendorLng = 0,
    this.deliveryAddress = '',
    this.deliveryLat = 0,
    this.deliveryLng = 0,
    this.driverEarning = 0,
    this.deliveryDistance = 0,
    this.items = const [],
    required this.createdAt,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> j) {
    final customer = j['customerId'] is Map<String, dynamic> ? j['customerId'] as Map<String, dynamic> : null;
    final vendor = j['vendorId'] is Map<String, dynamic> ? j['vendorId'] as Map<String, dynamic> : null;
    final addr = j['deliveryAddress'] is Map<String, dynamic> ? j['deliveryAddress'] as Map<String, dynamic> : null;
    final vAddr = vendor?['address'] is Map<String, dynamic> ? vendor!['address'] as Map<String, dynamic> : null;
    final vLoc = vAddr?['location'] is Map<String, dynamic> ? vAddr!['location'] as Map<String, dynamic> : null;

    final rawItems = j['products'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((p) => p is Map<String, dynamic> ? OrderItem.fromJson(p) : null)
        .whereType<OrderItem>()
        .toList();

    return DeliveryOrder(
      id: j['_id'] ?? '',
      orderStatus: j['orderStatus'] ?? 'pending',
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (j['deliveryCharge'] as num?)?.toDouble() ?? 0,
      paymentMethod: j['paymentMethod'] ?? 'cod',
      orderOTP: j['orderOTP'] ?? '',
      customerName: customer?['name'] ?? '',
      customerPhone: customer?['phone'] ?? '',
      vendorName: vendor?['shopName'] ?? '',
      vendorPhone: vendor?['phone'] ?? '',
      vendorAddress: vAddr?['fullAddress'] ?? '',
      vendorLat: (vLoc?['latitude'] as num?)?.toDouble() ?? 0,
      vendorLng: (vLoc?['longitude'] as num?)?.toDouble() ?? 0,
      deliveryAddress: addr?['fullAddress'] ?? '',
      deliveryLat: (addr?['latitude'] as num?)?.toDouble() ?? 0,
      deliveryLng: (addr?['longitude'] as num?)?.toDouble() ?? 0,
      driverEarning: (j['driverEarning'] as num?)?.toDouble() ?? 0,
      deliveryDistance: (j['deliveryDistance'] as num?)?.toDouble() ?? 0,
      items: items,
      createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get shortId => '#${id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase()}';
}

class OrderItem {
  final String productName;
  final int quantity;
  final String unit;
  final double price;
  final String image;

  const OrderItem({
    required this.productName,
    required this.quantity,
    this.unit = '',
    required this.price,
    this.image = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) {
    final prod = j['productId'] is Map<String, dynamic> ? j['productId'] as Map<String, dynamic> : null;
    final imgs = prod?['images'] as List<dynamic>?;
    final rawImg = imgs?.isNotEmpty == true ? imgs!.first.toString() : '';
    return OrderItem(
      productName: prod?['productName'] ?? 'Product',
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      unit: prod?['unit'] ?? '',
      price: (j['price'] as num?)?.toDouble() ?? 0,
      image: AppConstants.buildImageUrl(rawImg),
    );
  }
}
