class BannerItem {
  final String id;
  final String imageUrl;
  final String title;
  final bool isActive;

  const BannerItem({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.isActive = true,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json, String imageBaseUrl) {
    final raw = (json['image'] as String? ?? '').trim();
    final url = raw.isEmpty
        ? ''
        : raw.startsWith('http')
            ? raw
            : '$imageBaseUrl${raw.replaceAll('\\', '/')}';
    return BannerItem(
      id: json['_id'] as String? ?? '',
      imageUrl: url,
      title: (json['title'] as String? ?? '').trim(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
