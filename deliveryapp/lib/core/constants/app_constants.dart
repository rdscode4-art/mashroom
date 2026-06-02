class AppConstants {
  static const String baseUrl =
      'https://mushroomback.ridealdigitalseva.com/api';
  static const String imageBaseUrl =
      'https://mushroomback.ridealdigitalseva.com/';
  static const String tokenKey = 'delivery_token';

  static String buildImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$imageBaseUrl${path.replaceAll('\\', '/')}';
  }
}
