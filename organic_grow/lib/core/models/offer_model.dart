class Offer {
  final String id;
  final String title;
  final String discountText;
  final String description;
  final String badgeText;
  final String image; // full URL or empty

  const Offer({
    required this.id,
    required this.title,
    required this.discountText,
    required this.description,
    required this.badgeText,
    this.image = '',
  });

  factory Offer.fromJson(Map<String, dynamic> json, {String imageBaseUrl = ''}) {
    final raw = (json['image'] as String? ?? '').trim();
    String imageUrl = '';
    if (raw.isNotEmpty) {
      imageUrl = raw.startsWith('http')
          ? raw
          : '$imageBaseUrl${raw.replaceAll('\\', '/')}';
    }
    return Offer(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Special Offer',
      discountText: json['discountText'] ?? 'Discount',
      description: json['description'] ?? '',
      badgeText: json['badgeText'] ?? '',
      image: imageUrl,
    );
  }
}
