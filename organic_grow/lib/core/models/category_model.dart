class Category {
  final String id;
  final String name;
  final String icon;
  final String? image;
  final int itemCount;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.image,
    this.itemCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      image: json['image'] as String?,
      itemCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }
}