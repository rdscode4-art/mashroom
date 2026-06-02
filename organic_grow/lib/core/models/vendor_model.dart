class Vendor {
  final String id;
  final String shopName;
  final String ownerName;
  final String phone;
  final String shopImage;
  final String shopBanner;
  final String description;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final String deliveryTime;
  final double minimumOrder;
  final double deliveryCharge;
  final bool isOpen;
  final bool isApproved;
  final bool isOnline;
  final List<String> cuisineTags;
  final String fullAddress;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final double? distance;

  Vendor({
    required this.id,
    required this.shopName,
    this.ownerName = '',
    this.phone = '',
    this.shopImage = '',
    this.shopBanner = '',
    this.description = '',
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.deliveryTime = '30-45 mins',
    this.minimumOrder = 100,
    this.deliveryCharge = 30,
    this.isOpen = true,
    this.isApproved = false,
    this.isOnline = false,
    this.cuisineTags = const [],
    this.fullAddress = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.distance,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    final address = json['address'] ?? {};
    final location = address['location'] ?? {};

    return Vendor(
      id: json['_id'] ?? json['id'] ?? '',
      shopName: json['shopName'] ?? json['name'] ?? '',
      ownerName: json['ownerName'] ?? json['name'] ?? '',
      phone: json['phone'] ?? '',
      shopImage: json['shopImage'] ?? '',
      shopBanner: json['shopBanner'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      deliveryTime: json['deliveryTime'] ?? '30-45 mins',
      minimumOrder: (json['minimumOrder'] ?? 100).toDouble(),
      deliveryCharge: (json['deliveryCharge'] ?? 30).toDouble(),
      isOpen: json['isOpen'] ?? true,
      isApproved: json['isApproved'] ?? false,
      isOnline: json['isOnline'] ?? false,
      cuisineTags: List<String>.from(json['cuisineTags'] ?? []),
      fullAddress: address['fullAddress'] ?? '',
      city: address['city'] ?? '',
      state: address['state'] ?? '',
      pincode: address['pincode'] ?? '',
      latitude: (location['latitude'] ?? 0).toDouble(),
      longitude: (location['longitude'] ?? 0).toDouble(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'shopName': shopName,
      'ownerName': ownerName,
      'phone': phone,
      'shopImage': shopImage,
      'shopBanner': shopBanner,
      'description': description,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'deliveryTime': deliveryTime,
      'minimumOrder': minimumOrder,
      'deliveryCharge': deliveryCharge,
      'isOpen': isOpen,
      'isApproved': isApproved,
      'isOnline': isOnline,
      'cuisineTags': cuisineTags,
      if (distance != null) 'distance': distance,
      'address': {
        'fullAddress': fullAddress,
        'city': city,
        'state': state,
        'pincode': pincode,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
      },
    };
  }
}
