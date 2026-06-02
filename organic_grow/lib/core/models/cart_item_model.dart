class CartItem {
  String id;
  String name;
  double price;
  String image;
  int quantity;
  String vendorId;
  String vendorName;
  String unit;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
    this.vendorId = '',
    this.vendorName = '',
    this.unit = 'kg',
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? '',
      quantity: json['quantity'] ?? 1,
      vendorId: json['vendorId'] ?? '',
      vendorName: json['vendorName'] ?? '',
      unit: json['unit'] ?? 'kg',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'quantity': quantity,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'unit': unit,
    };
  }
}