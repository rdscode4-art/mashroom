class Product {
  final String id;
  final String name;
  final double price;
  final double mrpPrice;
  final String image;
  final List<String> images;
  final double rating;
  final String categoryId;
  final String categoryName;
  final String description;
  final String unit;
  final String weight;
  final int stock;
  final String vendorId;
  final String vendorName;
  final bool isAvailable;
  final bool isFeatured;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.mrpPrice = 0,
    required this.image,
    this.images = const [],
    required this.rating,
    this.categoryId = '',
    this.categoryName = '',
    this.description = 'Fresh organic produce harvested directly from local sustainable farms.',
    this.unit = 'kg',
    this.weight = '',
    this.stock = 10,
    this.vendorId = '',
    this.vendorName = '',
    this.isAvailable = true,
    this.isFeatured = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse images
    final List<dynamic> imgs = json['images'] ?? [];
    List<String> imageList = imgs.map((e) => e.toString().replaceAll('\\', '/')).toList();
    String primaryImage = imageList.isNotEmpty ? imageList[0] : '';

    // Parse category
    final catObj = json['categoryId'];
    String catId = '';
    String catName = '';
    if (catObj is Map) {
      catId = catObj['_id'] ?? '';
      catName = catObj['name'] ?? '';
    } else if (catObj is String) {
      catId = catObj;
    }

    // Parse vendor
    final vendorObj = json['vendorId'] ?? json['vendor'];
    String vId = '';
    String vName = '';
    if (vendorObj is Map) {
      vId = vendorObj['_id'] ?? vendorObj['id'] ?? '';
      vName = vendorObj['shopName'] ?? vendorObj['name'] ?? '';
    } else if (vendorObj is String) {
      vId = vendorObj;
    }

    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['productName'] ?? '',
      price: (json['sellingPrice'] ?? json['mrpPrice'] ?? 0).toDouble(),
      mrpPrice: (json['mrpPrice'] ?? 0).toDouble(),
      image: primaryImage,
      images: imageList,
      rating: (json['rating'] ?? 0).toDouble(),
      categoryId: catId,
      categoryName: catName,
      description: json['description'] ?? 'Fresh organic produce harvested directly from local sustainable farms.',
      unit: json['unit'] ?? 'kg',
      weight: json['weight'] ?? '',
      stock: (json['stock'] ?? 10) is int ? json['stock'] : 10,
      vendorId: vId,
      vendorName: vName,
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
    );
  }
}